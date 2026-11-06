#import "StdPatch/StdPatch.h"
#import <AppKit/AppKit.h>
#import <libproc.h>
#import <signal.h>
#import <sys/sysctl.h>
#import "Patches/OwnModel/OwnModel.h"

extern DPPatch DPOwnModel;

NSString *const DPOwnModelEndpointKey = @"ownModelEndpoint";
NSString *const DPOwnModelModelKey = @"ownModelModel";
NSString *const DPOwnModelEffortKey = @"ownModelEffort";
NSString *const DPOwnModelTokenKey = @"ownModelToken";

// Dia answers with the Claude Code it ships, running in a sandbox whose only network way out is a local gateway to
// Dia's own servers. This patch points that agent at an Anthropic-compatible endpoint of yours instead: the same
// Claude Code, the same tools, your model.
//
// The endpoint, model, effort and token live in com.diapatches and are read per request, so a change in Settings
// applies to the next message.
static NSUserDefaults *DPOwnModelDefaults(void) {
    static NSUserDefaults *defaults;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.diapatches"]; });
    return defaults;
}

static NSString *DPOwnModelValue(NSString *key, NSString *fallback) {
    id value = [DPOwnModelDefaults() objectForKey:key];
    if ([value isKindOfClass:NSString.class] && [value length]) return value;
    return fallback;
}

NSString *DPOwnModelEndpoint(void) {
    return DPOwnModelValue(DPOwnModelEndpointKey, @"http://127.0.0.1:3425");
}

NSString *DPOwnModelModel(void) {
    return DPOwnModelValue(DPOwnModelModelKey, @"auto/deepseek-v4.1-flash[1m]");
}

NSString *DPOwnModelEffort(void) { return DPOwnModelValue(DPOwnModelEffortKey, nil); }

NSString *DPOwnModelToken(void) { return DPOwnModelValue(DPOwnModelTokenKey, nil); }

// Claude Code talks to the relay, which can change what Dia's agent specs pin down; without it, it talks to the
// endpoint itself and only the address changes.
static NSString *DPOwnModelBase(void) {
    uint16_t port = DPRelayStart();
    return port ? [NSString stringWithFormat:@"http://127.0.0.1:%u", port] : DPOwnModelEndpoint();
}

// The port on localhost to let the sandbox reach, or nil when the endpoint is somewhere else.
static NSString *DPOwnModelPort(void) {
    NSURLComponents *parts = [NSURLComponents componentsWithString:DPOwnModelBase()];
    NSString *host = parts.host.lowercaseString;
    if (![host isEqualToString:@"localhost"] && ![host isEqualToString:@"127.0.0.1"] && ![host isEqualToString:@"::1"]) return nil;
    return parts.port.stringValue ?: ([parts.scheme.lowercaseString isEqualToString:@"https"] ? @"443" : @"80");
}

static NSString *DPOwnModelProfilePath(void) {
    return DPAppSupport(@"DiaPatches/own-model.sb");
}

// Dia hands Claude Code the sandbox profile it ships. This keeps that profile and adds the endpoint's port, since
// Dia's own rule only allows the gateway it starts.
static BOOL DPWriteOwnModelProfile(void) {
    NSString *shipped = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:
        @"Contents/Resources/agent-server-resources/dist/agent-claude-code.sb"];
    NSString *text = [NSString stringWithContentsOfFile:shipped encoding:NSUTF8StringEncoding error:nil];
    NSString *port = DPOwnModelPort();
    if (!text || !port) return NO;
    NSString *rule = [NSString stringWithFormat:@"\n;; DiaTweaks: the model endpoint the Own Model tweak points Claude Code at.\n"
                                                 "(allow network-outbound (remote tcp \"localhost:%@\"))\n", port];
    NSString *path = DPOwnModelProfilePath();
    NSString *current = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSString *wanted = [text stringByAppendingString:rule];
    if ([current isEqualToString:wanted]) return YES;
    return [wanted writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

static BOOL DPIsAgentServer(const char *path) {
    return path && strstr(path, "/agent-server-resources/dist/agent-server") != NULL;
}

// Dia starts the agent server from its own environment, so the endpoint and the sandbox profile go on the spawn.
// Everything below it inherits them.
static void DPOwnModelSpawn(DPSpawn *spawn) {
    if (!DPOwnModel.on || !DPIsAgentServer(spawn->path)) return;
    NSString *profile = DPOwnModelProfilePath();
    if (![NSFileManager.defaultManager fileExistsAtPath:profile] && !DPWriteOwnModelProfile()) return;
    NSString *base = DPOwnModelBase();
    spawn->env = DPEnvBySetting(spawn->env, @{
        @"CLAUDE_CODE_USE_VERTEX": @"0",
        @"ANTHROPIC_BASE_URL": base,
        @"CLAUDE_CODE_SANDBOX_PROFILE": profile,
    });
}

static pid_t DPAgentServerPID(void) {
    int count = proc_listchildpids(getpid(), NULL, 0);
    if (count <= 0) return 0;
    pid_t pids[count];
    count = proc_listchildpids(getpid(), pids, sizeof pids);
    for (int i = 0; i < count; i++) {
        char path[PROC_PIDPATHINFO_MAXSIZE] = {0};
        if (proc_pidpath(pids[i], path, sizeof path) > 0 && DPIsAgentServer(path)) return pids[i];
    }
    return 0;
}

static NSDictionary<NSString *, NSString *> *DPProcessEnvironment(pid_t pid) {
    int mib[] = {CTL_KERN, KERN_PROCARGS2, pid};
    size_t size = 0;
    if (sysctl(mib, 3, NULL, &size, NULL, 0) || size < sizeof(int)) return nil;
    char *buffer = malloc(size), *end = buffer + size, *p = buffer + sizeof(int);
    if (sysctl(mib, 3, buffer, &size, NULL, 0)) return free(buffer), nil;
    int argc = *(int *)buffer;
    while (p < end && *p) p++;
    while (p < end && !*p) p++;
    for (int i = 0; i < argc && p < end; i++, p++) while (p < end && *p) p++;
    while (p < end && !*p) p++;
    NSMutableDictionary *env = [NSMutableDictionary new];
    while (p < end && *p) {
        NSString *entry = [NSString stringWithUTF8String:p];
        NSRange equals = [entry rangeOfString:@"="];
        if (equals.location != NSNotFound) env[[entry substringToIndex:equals.location]] = [entry substringFromIndex:equals.location + 1];
        p += strlen(p) + 1;
    }
    free(buffer);
    return env;
}

// The agent server reads its environment once, at launch, so a change to these needs it to start again. Dia starts
// another one the next time a chat needs it.
static void DPRestartAgentServer(void) {
    pid_t pid = DPAgentServerPID();
    if (pid) kill(pid, SIGTERM);
}

static void DPApplyOwnModel(DPPatch *patch) {
    static int lastOn = -1;
    DPWriteOwnModelProfile();
    if (lastOn >= 0 && lastOn != patch->on) DPRestartAgentServer();
    lastOn = patch->on;
}

static NSString *DPVerifyOwnModel(DPPatch *patch) {
    pid_t pid = DPAgentServerPID();
    if (!pid) return nil;
    BOOL ours = [DPProcessEnvironment(pid)[@"ANTHROPIC_BASE_URL"] isEqualToString:DPOwnModelBase()];
    if (ours == patch->on) return nil;
    return patch->on ? @"the agent server still answers with Dia's models" : @"the agent server still answers with your model";
}

static void DPInstallOwnModel(void) {
    DPRelayStart();
    DPWriteOwnModelProfile();
    DPOnSpawn(DPOwnModelSpawn);
}

DP_PATCH(DPOwnModel) {
    .key = @"ownModel",
    .order = 60,
    .title = @"Answer with Your Own Model",
    .detail = @"Dia answers with the Claude Code it ships. Point that at your own Anthropic-compatible endpoint instead of Dia's servers, and pick the model and how hard it thinks.",
    .symbol = @"brain.head.profile",
    .tint = @"systemPurpleColor",
    .section = @"Other",
    .rows = DPOwnModelRows,
    .install = DPInstallOwnModel,
    .apply = DPApplyOwnModel,
    .verify = DPVerifyOwnModel,
};
