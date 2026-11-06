#import <Foundation/Foundation.h>

extern NSString *const DPOwnModelEndpointKey, *const DPOwnModelModelKey, *const DPOwnModelEffortKey, *const DPOwnModelTokenKey;

// The endpoint Claude Code talks to, its token, and what the local relay puts into each request.
NSString *DPOwnModelEndpoint(void);
NSString *DPOwnModelModel(void);
NSString *DPOwnModelEffort(void);  // nil for Dia's own, else off, low, medium, high, xhigh or max
NSString *DPOwnModelToken(void);   // nil keeps the token Claude Code sent

uint16_t DPRelayStart(void);  // The port the relay listens on, 0 if it couldn't.
NSArray<NSView *> *DPOwnModelRows(void);
