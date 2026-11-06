#import "StdPatch/StdPatch.h"
#import <arpa/inet.h>
#import <netinet/in.h>
#import <sys/socket.h>

// Dia pins the model and the effort in the agent specs it ships and hands them to Claude Code in the SDK options, so
// environment variables can't change them. Claude Code does honor ANTHROPIC_BASE_URL, so it talks to this instead: a
// small local proxy that swaps the model, thinking and effort in each request's JSON and forwards it to the endpoint
// from Settings. Reading the settings per request means a change applies to the next message.
extern NSString *DPOwnModelEndpoint(void);
extern NSString *DPOwnModelModel(void);
extern NSString *DPOwnModelEffort(void);  // nil for Dia's own, else off, low, medium, high, xhigh or max
extern NSString *DPOwnModelToken(void);

static uint16_t DPRelayPort;
static int DPRelayFD = -1;

@interface DPRelayConnection : NSObject <NSURLSessionDataDelegate>
@property(nonatomic) int fd;
@property(nonatomic, strong) NSString *head;
@property(nonatomic, strong) NSData *body;
@property(nonatomic, strong) NSURLSession *session;
@property(nonatomic) BOOL sentHeaders, closed;
@end

static BOOL DPWriteAll(int fd, NSData *data) {
    const char *bytes = data.bytes;
    size_t left = data.length;
    while (left) {
        ssize_t written = send(fd, bytes, left, 0);
        if (written <= 0) return NO;
        bytes += written;
        left -= written;
    }
    return YES;
}

static void DPWriteChunk(DPRelayConnection *connection, NSData *data) {
    if (!data.length || connection.closed) return;
    NSMutableData *chunk = [NSMutableData new];
    [chunk appendData:[[NSString stringWithFormat:@"%lx\r\n", (unsigned long)data.length] dataUsingEncoding:NSUTF8StringEncoding]];
    [chunk appendData:data];
    [chunk appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    DPWriteAll(connection.fd, chunk);
}

static void DPClose(DPRelayConnection *connection) {
    if (connection.closed) return;
    connection.closed = YES;
    close(connection.fd);
    [connection.session invalidateAndCancel];
}

// The request Claude Code sends, with the model and effort chosen in Settings.
static NSData *DPRelayBody(NSData *body) {
    NSMutableDictionary *json = [NSJSONSerialization JSONObjectWithData:body options:NSJSONReadingMutableContainers error:nil];
    if (![json isKindOfClass:NSMutableDictionary.class]) return body;
    NSString *model = DPOwnModelModel();
    if (model.length) json[@"model"] = model;
    NSString *effort = DPOwnModelEffort();
    if ([effort isEqualToString:@"off"]) {
        json[@"thinking"] = @{ @"type" : @"disabled" };
        [json removeObjectForKey:@"output_config"];
    } else if (effort.length) {
        NSMutableDictionary *output = [json[@"output_config"] isKindOfClass:NSMutableDictionary.class]
            ? json[@"output_config"] : [NSMutableDictionary new];
        output[@"effort"] = effort;
        json[@"output_config"] = output;
    }
    return [NSJSONSerialization dataWithJSONObject:json options:0 error:nil] ?: body;
}

static NSString *DPRelayUpstreamURL(NSString *path) {
    NSString *endpoint = DPOwnModelEndpoint();
    if ([path hasPrefix:@"/"] && [endpoint hasSuffix:@"/"]) endpoint = [endpoint substringToIndex:endpoint.length - 1];
    return [endpoint stringByAppendingString:path];
}

@implementation DPRelayConnection

- (NSString *)header:(NSString *)name {
    for (NSString *line in [self.head componentsSeparatedByString:@"\r\n"]) {
        NSRange colon = [line rangeOfString:@":"];
        if (colon.location == NSNotFound) continue;
        if ([[line substringToIndex:colon.location] caseInsensitiveCompare:name] == NSOrderedSame)
            return [[line substringFromIndex:colon.location + 1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    }
    return nil;
}

- (void)start {
    NSArray<NSString *> *parts = [[self.head componentsSeparatedByString:@"\r\n"].firstObject componentsSeparatedByString:@" "];
    if (parts.count < 2) return DPClose(self);
    NSMutableURLRequest *upstream = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:DPRelayUpstreamURL(parts[1])]];
    upstream.HTTPMethod = parts[0];
    upstream.timeoutInterval = 600;
    for (NSString *header in @[ @"content-type", @"anthropic-version", @"anthropic-beta", @"accept" ]) {
        NSString *value = [self header:header];
        if (value) [upstream setValue:value forHTTPHeaderField:header];
    }
    NSString *token = DPOwnModelToken();
    NSString *authorization = token.length ? [@"Bearer " stringByAppendingString:token] : [self header:@"authorization"];
    if (authorization) [upstream setValue:authorization forHTTPHeaderField:@"Authorization"];
    upstream.HTTPBody = DPRelayBody(self.body);
    self.session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.ephemeralSessionConfiguration delegate:self delegateQueue:nil];
    [[self.session dataTaskWithRequest:upstream] resume];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)task
    didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    self.sentHeaders = YES;
    NSHTTPURLResponse *http = [response isKindOfClass:NSHTTPURLResponse.class] ? (NSHTTPURLResponse *)response : nil;
    NSString *type = http.allHeaderFields[@"Content-Type"] ?: @"application/json";
    NSString *head = [NSString stringWithFormat:@"HTTP/1.1 %ld OK\r\nContent-Type: %@\r\nTransfer-Encoding: chunked\r\nConnection: close\r\n\r\n",
                                                (long)(http ? http.statusCode : 200), type];
    DPWriteAll(self.fd, [head dataUsingEncoding:NSUTF8StringEncoding]);
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)task didReceiveData:(NSData *)data {
    DPWriteChunk(self, data);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (self.sentHeaders) {
        DPWriteAll(self.fd, [@"0\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]);
    } else {
        NSDictionary *failure = @{ @"error" : @{ @"type" : @"api_error", @"message" : error.localizedDescription ?: @"No response" } };
        NSData *body = [NSJSONSerialization dataWithJSONObject:failure options:0 error:nil];
        NSString *head = [NSString stringWithFormat:@"HTTP/1.1 502 Bad Gateway\r\nContent-Type: application/json\r\nContent-Length: %lu\r\nConnection: close\r\n\r\n",
                                                    (unsigned long)body.length];
        DPWriteAll(self.fd, [head dataUsingEncoding:NSUTF8StringEncoding]);
        DPWriteAll(self.fd, body);
    }
    DPClose(self);
}

@end

// Reads one request from a connection, then lets DPRelayConnection send it on.
static void DPRelayRead(DPRelayConnection *connection) {
    NSMutableData *input = [NSMutableData new];
    char buffer[16384];
    BOOL parsed = NO;
    NSUInteger headLength = 0, contentLength = 0;
    while (!connection.closed) {
        ssize_t count = recv(connection.fd, buffer, sizeof buffer, 0);
        if (count <= 0) return DPClose(connection);
        [input appendBytes:buffer length:count];
        if (!parsed) {
            NSRange end = [input rangeOfData:[@"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding] options:0 range:NSMakeRange(0, input.length)];
            if (end.location == NSNotFound) continue;
            parsed = YES;
            headLength = NSMaxRange(end);
            connection.head = [[NSString alloc] initWithData:[input subdataWithRange:NSMakeRange(0, headLength)] encoding:NSUTF8StringEncoding];
            for (NSString *line in [connection.head componentsSeparatedByString:@"\r\n"]) {
                if ([line.lowercaseString hasPrefix:@"content-length:"]) contentLength = [line substringFromIndex:15].integerValue;
            }
            if ([connection.head rangeOfString:@"Expect: 100-continue"].location != NSNotFound)
                DPWriteAll(connection.fd, [@"HTTP/1.1 100 Continue\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]);
        }
        if (input.length < headLength + contentLength) continue;
        connection.body = [input subdataWithRange:NSMakeRange(headLength, contentLength)];
        [connection start];
        return;
    }
}

static uint16_t DPRelayListen(void) {
    for (uint16_t port = 3472; port < 3482; port++) {
        int fd = socket(AF_INET, SOCK_STREAM, 0);
        if (fd < 0) return 0;
        int on = 1;
        setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &on, sizeof on);
        struct sockaddr_in address = { .sin_family = AF_INET, .sin_port = htons(port), .sin_addr.s_addr = htonl(INADDR_LOOPBACK) };
        if (bind(fd, (struct sockaddr *)&address, sizeof address) || listen(fd, 16)) {
            close(fd);
            continue;
        }
        DPRelayFD = fd;
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            while (DPRelayFD >= 0) {
                int client = accept(fd, NULL, NULL);
                if (client < 0) continue;
                DPRelayConnection *connection = [DPRelayConnection new];
                connection.fd = client;
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{ DPRelayRead(connection); });
            }
        });
        return port;
    }
    return 0;
}

uint16_t DPRelayStart(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{ DPRelayPort = DPRelayListen(); });
    return DPRelayPort;
}
