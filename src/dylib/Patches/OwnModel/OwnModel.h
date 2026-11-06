#import <Foundation/Foundation.h>

extern NSString *const DPOwnModelEndpointKey, *const DPOwnModelModelKey, *const DPOwnModelEffortKey, *const DPOwnModelTokenKey;

// The endpoint Claude Code talks to, its token, and what the local relay puts into each request.
NSString *DPOwnModelEndpoint(void);
NSString *DPOwnModelModel(void);
NSString *DPOwnModelEffort(void);  // nil for Dia's own, else off, low, medium, high, xhigh or max
NSString *DPOwnModelToken(void);   // nil keeps the token Claude Code sent

uint16_t DPRelayStart(void);  // The port the relay listens on, 0 if it couldn't.
NSArray<NSView *> *DPOwnModelRows(void);

// What other patches ask about the agent server Dia runs under itself.
BOOL DPIsAgentServer(const char *path);
pid_t DPAgentServerPID(void);  // Dia's agent server, 0 when it isn't running.
NSDictionary<NSString *, NSString *> *DPAgentServerEnvironment(pid_t pid);
void DPRestartAgentServer(void);  // It reads its environment once, so a change needs it started again.
