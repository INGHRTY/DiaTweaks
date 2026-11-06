#import "StdPatch/Hide.h"

// During a Better Days trial Dia replaces the chat button with this pill, titled with the plan name.
static BOOL DPIsBetterDaysButton(NSView *view) {
    return DPIsKind(view, DPDiaAdvancedChatUpsell) || DPIsKind(view, DPDiaAdvancedChatUpsellControl);
}

// The pill isn't inside one of the hide hosts, so enforce from its own layout.
static void DPBetterDaysButton_layout(NSView *self, SEL _cmd) {
    [DPHideHosts addObject:self];
    DPEnforceHides(self);
    DPCallOriginal(DPBetterDaysButton_layout, self);
}

static void DPInstallHideBetterDaysButton(void) {
    DPHook(DPDiaAdvancedChatUpsell, @selector(layout), (IMP)DPBetterDaysButton_layout);
    DPHook(DPDiaAdvancedChatUpsellControl, @selector(layout), (IMP)DPBetterDaysButton_layout);
}

DP_PATCH(DPHideBetterDaysButton) {
    .key = @"hideBetterDaysButton",
    .order = 115,
    .title = @"Hide Better Days Button",
    .detail = @"Hide the “Better Days Trial” upgrade pill at the top of the chat panel.",
    .symbol = @"crown.fill",
    .tint = @"systemIndigoColor",
    .section = @"Toolbar",
    .classes = DPClasses(DPDiaAdvancedChatUpsell, DPDiaAdvancedChatUpsellControl),
    .hides = DPIsBetterDaysButton,
    .install = DPInstallHideBetterDaysButton,
};
