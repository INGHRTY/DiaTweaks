#import "StdPatch/StdPatch.h"
#import <signal.h>
#import "Patches/OwnModel/OwnModel.h"

extern DPPatch DPAutoApprove;

// Before the assistant clicks, types or downloads, the handler Dia runs asks the app for permission and waits for an
// answer, which is the dialog that interrupts every chat. The question is asked by JavaScript inside the handler, so
// this patch answers it there: Dia's own handler, copied out and changed in one place to allow the tool as soon as it
// is checked. Dia's bundle keeps its signature; agent-server takes another handler from its environment when
// AGENT_SERVER_TEST_MODE is 1.

static NSString *DPHandlerSource(void) {
    return [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:
        @"Contents/Resources/agent-server-resources/dist/handler"];
}

static NSString *DPHandlerCopy(void) {
    return DPAppSupport(@"DiaPatches/handler");
}

// What the copy was made from, so Dia updating its handler gets it copied again.
static NSString *DPHandlerStamp(void) {
    return DPAppSupport(@"DiaPatches/handler.source");
}

// The call to the app that shows the dialog: `let V = await t.onCheck("permission", {...}, f(pe)).catch(() => null)`.
// Its result, "allow" here, is what the handler then acts on. Everything from the start of that statement to the end
// of the promise goes, replaced by the answer with spaces in its place, so every other byte keeps its offset.
static BOOL DPPatchHandler(NSMutableData *data) {
    static const char *anchor = "await t.onCheck(\"permission\"";
    static const char *tail = ".catch(() => null)";
    static const char *answer = " '{\"decision\":\"allow\"}'";
    size_t anchorLength = strlen(anchor), tailLength = strlen(tail);
    uint8_t *bytes = data.mutableBytes;
    NSUInteger length = data.length;

    NSMutableArray<NSValue *> *spans = [NSMutableArray new];
    NSMutableArray<NSString *> *answers = [NSMutableArray new];
    for (NSUInteger i = 0; i + anchorLength <= length; i++) {
        if (memcmp(bytes + i, anchor, anchorLength)) continue;
        NSUInteger start = i;
        while (start > 0 && bytes[start - 1] != '\n') start--;
        NSUInteger end = NSNotFound;
        for (NSUInteger j = i; j + tailLength <= length; j++)
            if (!memcmp(bytes + j, tail, tailLength)) { end = j + tailLength; break; }
        NSString *head = end == NSNotFound ? nil
            : [[NSString alloc] initWithBytes:bytes + start length:i - start encoding:NSUTF8StringEncoding];
        if (!head) return NO;
        NSRange assign = [head rangeOfString:@"="];
        if (assign.location == NSNotFound) return NO;
        NSString *wanted = [[head substringToIndex:NSMaxRange(assign)] stringByAppendingString:@(answer)];
        if (wanted.length > end - start) return NO;
        [spans addObject:[NSValue valueWithRange:NSMakeRange(start, end - start)]];
        [answers addObject:[wanted stringByPaddingToLength:end - start withString:@" " startingAtIndex:0]];
    }
    if (!spans.count) return NO;
    for (NSInteger i = (NSInteger)spans.count - 1; i >= 0; i--) {  // From the end, so earlier offsets stay good.
        NSRange span = spans[(NSUInteger)i].rangeValue;
        [answers[(NSUInteger)i] getBytes:bytes + span.location maxLength:span.length usedLength:NULL
                                encoding:NSUTF8StringEncoding options:0 range:NSMakeRange(0, span.length)
                                 remainingRange:NULL];
    }
    return YES;
}

static BOOL DPSignHandler(NSString *path) {
    NSString *entitlements = DPAppSupport(@"DiaPatches/handler.entitlements");
    NSString *text = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
        "<plist version=\"1.0\"><dict><key>com.apple.security.cs.allow-jit</key><true/></dict></plist>\n";
    if (![NSFileManager.defaultManager fileExistsAtPath:entitlements])
        [text writeToFile:entitlements atomically:YES encoding:NSUTF8StringEncoding error:nil];

    NSTask *task = [NSTask new];  // Changing the binary's bytes voids Dia's signature, so it signs its own.
    task.executableURL = [NSURL fileURLWithPath:@"/usr/bin/codesign"];
    task.arguments = @[ @"--force", @"--sign", @"-", @"--entitlements", entitlements, path ];
    task.standardOutput = [NSFileHandle fileHandleWithNullDevice];
    task.standardError = [NSFileHandle fileHandleWithNullDevice];
    if (![task launchAndReturnError:nil]) return NO;
    [task waitUntilExit];
    return task.terminationStatus == 0;
}

static BOOL DPBuildHandlerCopy(void) {
    NSString *source = DPHandlerSource();
    NSDictionary *file = [NSFileManager.defaultManager attributesOfItemAtPath:source error:nil];
    NSString *stamp = file ? [NSString stringWithFormat:@"%@ %@", file[NSFileSize], file[NSFileModificationDate]] : nil;
    NSString *current = [NSString stringWithContentsOfFile:DPHandlerStamp() encoding:NSUTF8StringEncoding error:nil];
    if (stamp && [current isEqualToString:stamp] && [NSFileManager.defaultManager isExecutableFileAtPath:DPHandlerCopy()])
        return YES;

    NSMutableData *data = [NSMutableData dataWithContentsOfFile:source];
    if (!data || !DPPatchHandler(data)) return NO;
    NSString *copy = DPHandlerCopy();
    if (![data writeToFile:copy atomically:YES]) return NO;
    [NSFileManager.defaultManager setAttributes:@{ NSFilePosixPermissions : @0755 } ofItemAtPath:copy error:nil];
    if (!DPSignHandler(copy)) return NO;
    [stamp writeToFile:DPHandlerStamp() atomically:YES encoding:NSUTF8StringEncoding error:nil];
    return YES;
}

static void DPAutoApproveSpawn(DPSpawn *spawn) {
    if (!DPAutoApprove.on || !DPIsAgentServer(spawn->path)) return;
    if (!DPBuildHandlerCopy()) return;
    spawn->env = DPEnvBySetting(spawn->env, @{
        @"AGENT_SERVER_TEST_MODE": @"1",
        @"AGENT_SERVER_HANDLER_BINARY_PATH": DPHandlerCopy(),
    });
}

static void DPApplyAutoApprove(DPPatch *patch) {
    static int lastOn = -1;
    if (lastOn >= 0 && lastOn != patch->on) DPRestartAgentServer();
    lastOn = patch->on;
    if (patch->on) dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{ DPBuildHandlerCopy(); });
}

static NSString *DPVerifyAutoApprove(DPPatch *patch) {
    pid_t pid = DPAgentServerPID();
    if (!pid) return nil;
    NSDictionary<NSString *, NSString *> *env = DPAgentServerEnvironment(pid);
    BOOL ours = [env[@"AGENT_SERVER_TEST_MODE"] isEqualToString:@"1"] &&
        [env[@"AGENT_SERVER_HANDLER_BINARY_PATH"] isEqualToString:DPHandlerCopy()];
    if (ours == patch->on) return nil;
    return patch->on ? @"the agent server still asks before each action" : @"the agent server still answers by itself";
}

static void DPInstallAutoApprove(void) {
    DPOnSpawn(DPAutoApproveSpawn);
    if (!DPSavedOn(&DPAutoApprove)) return;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{ DPBuildHandlerCopy(); });
}

DP_PATCH(DPAutoApprove) {
    .key = @"autoApprove",
    .order = 61,
    .title = @"Skip the Approval Prompt",
    .detail = @"Before the assistant clicks, types or downloads anything, Dia asks you to allow it. This answers those questions for you, so the assistant does what you asked without stopping to ask.",
    .symbol = @"checkmark.shield",
    .tint = @"systemPurpleColor",
    .section = @"Other",
    .install = DPInstallAutoApprove,
    .apply = DPApplyAutoApprove,
    .verify = DPVerifyAutoApprove,
};
