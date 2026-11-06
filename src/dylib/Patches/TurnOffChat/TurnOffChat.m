#import "StdPatch/Hide.h"

#define DPDiaCapabilitiesToolbar "_TtC23AssistantCapabilitiesUI32AssistantCapabilitiesToolbarView"
#define DPDiaCapabilitiesItem    "_TtC23AssistantCapabilitiesUI36AssistantCapabilitiesToolbarItemView"
#define DPDiaSuggestionsView     "_TtC15BoostCommandBar15SuggestionsView"

extern DPPatch DPTurnOffChat;

static BOOL DPIsChatView(NSView *view) {
    return DPHasLabel(view, @"Chat with this tab") || DPIsKind(view, DPDiaLibraryButton) || DPIsKind(view, DPDiaLibraryCell)
        || DPIsKind(view, DPDiaSkillsSuggestions) || DPIsKind(view, DPDiaPersonalizeButton) || DPIsKind(view, DPDiaChatUsage)
        || DPIsKind(view, DPDiaCapabilitiesItem);
}

#pragma mark Menus

static BOOL DPIsChatItem(NSMenuItem *item) {
    NSString *title = item.title;
    if ([title hasPrefix:@"Chat with Support"]) return NO;
    return [@[ @"Chat…", @"New Chat", @"Focus Chat", @"Send Chat Prompt Now", @"Open Daily Brief" ] containsObject:title]
        || [title.lowercaseString hasPrefix:@"chat with "];
}

static NSHashTable<NSMenuItem *> *DPChatItems;
static char DPDiaHiddenKey;

// Dia shows and hides some of these itself, so what it asked for is kept and only added to.
static void DPItem_setHidden(NSMenuItem *self, SEL _cmd, BOOL hidden) {
    BOOL chat = [DPChatItems containsObject:self];
    if (chat) DPSet(self, &DPDiaHiddenKey, @(hidden));
    DPCallOriginal(DPItem_setHidden, self, hidden || (chat && DPTurnOffChat.on));
}

static void DPTrack(NSMenuItem *item) {
    if (!DPIsChatItem(item)) return;
    if (![DPChatItems containsObject:item]) {
        BOOL diaHidden = item.hidden;
        [DPChatItems addObject:item];
        DPSet(item, &DPDiaHiddenKey, @(diaHidden));
    }
    item.hidden = [DPGet(item, &DPDiaHiddenKey) boolValue];
}

static void DPTrackMenu(NSMenu *menu) {
    for (NSMenuItem *item in menu.itemArray) {
        DPTrack(item);
        if (item.submenu) DPTrackMenu(item.submenu);
    }
}

static void DPMenu_addItem(NSMenu *self, SEL _cmd, NSMenuItem *item) {
    DPCallOriginal(DPMenu_addItem, self, item);
    DPTrack(item);
}

static void DPMenu_insertItem(NSMenu *self, SEL _cmd, NSMenuItem *item, NSInteger index) {
    DPCallOriginal(DPMenu_insertItem, self, item, index);
    DPTrack(item);
}

#pragma mark Command bar

static NSView *DPAncestor(NSView *view, const char *className) {
    for (NSView *each = view; each; each = each.superview)
        if (DPIsKind(each, className)) return each;
    return nil;
}

// The command bar is outside the hide hosts. The toolbar itself stays, so the buttons right of it don't slide left.
static void DPCapabilities_layout(NSView *self, SEL _cmd) {
    [DPHideHosts addObject:self];
    DPEnforceHides(self);
    DPCallOriginal(DPCapabilities_layout, self);
}

static char DPChatRowsKey;

// Rows are only looked at between updates: asking a table for a view while it updates throws.
static BOOL DPIsChatRow(NSTableView *table, NSInteger row) { return [DPGet(table, &DPChatRowsKey) containsIndex:row]; }

static void DPFindChatRows(NSTableView *table) {
    NSMutableIndexSet *rows = [NSMutableIndexSet indexSet];
    for (NSInteger row = 0; DPTurnOffChat.on && row < table.numberOfRows; row++) {
        NSView *cell = [table viewAtColumn:0 row:row makeIfNecessary:NO];
        if (cell && DPFindView(cell, ^BOOL(NSView *view) { return [view isKindOfClass:NSImageView.class] && [view.accessibilityLabel isEqual:@"chat"]; }))
            [rows addIndex:row];
    }
    // Row views are reused, so every row is set each time, not only ones that changed.
    for (NSInteger row = 0; row < table.numberOfRows; row++) [table rowViewAtRow:row makeIfNecessary:NO].hidden = [rows containsIndex:row];
    NSIndexSet *before = DPGet(table, &DPChatRowsKey) ?: [NSIndexSet indexSet];
    if ([before isEqualToIndexSet:rows]) return;
    DPSet(table, &DPChatRowsKey, rows);
    NSMutableIndexSet *changed = [rows mutableCopy];
    [changed addIndexes:before];
    [changed removeIndexesInRange:NSMakeRange(table.numberOfRows, NSUIntegerMax - table.numberOfRows)];
    [table noteHeightOfRowsWithIndexesChanged:changed];
}

// Dia sizes the list from its own count of rows, so the space the row leaves stays at the bottom.
static CGFloat DPSuggestions_heightOfRow(id self, SEL _cmd, NSTableView *table, NSInteger row) {
    CGFloat height = DPCallOriginal(DPSuggestions_heightOfRow, self, table, row);
    return DPTurnOffChat.on && DPIsChatRow(table, row) ? 1 : height;
}

static void DPTable_endUpdates(NSTableView *self, SEL _cmd) {
    DPCallOriginal(DPTable_endUpdates, self);
    if (DPAncestor(self, DPDiaSuggestionsView)) DPFindChatRows(self);
}

static void DPTable_reloadData(NSTableView *self, SEL _cmd) {
    DPCallOriginal(DPTable_reloadData, self);
    if (DPAncestor(self, DPDiaSuggestionsView)) DPFindChatRows(self);
}

// Dia keeps its own idea of the selected suggestion, so landing on the chat row moves on the way the arrow key did.
static void DPTable_selectRows(NSTableView *self, SEL _cmd, NSIndexSet *rows, BOOL extend) {
    NSInteger from = self.selectedRow;
    DPCallOriginal(DPTable_selectRows, self, rows, extend);
    if (!DPTurnOffChat.on || rows.count != 1 || !DPIsChatRow(self, rows.firstIndex)) return;
    BOOL up = from > (NSInteger)rows.firstIndex && rows.firstIndex > 0;
    if (!up && rows.firstIndex + 1 >= (NSUInteger)self.numberOfRows) up = YES;
    NSResponder *editor = self.window.firstResponder;
    dispatch_async(dispatch_get_main_queue(), ^{ [editor doCommandBySelector:up ? @selector(moveUp:) : @selector(moveDown:)]; });
}

static const NSEventModifierFlags DPModifiers = NSEventModifierFlagCommand | NSEventModifierFlagControl | NSEventModifierFlagOption | NSEventModifierFlagShift;

// Dia runs its shortcuts, ones set in its Shortcuts settings included, ahead of the menus, so a hidden item's still works.
static BOOL DPIsChatShortcut(NSEvent *event) {
    NSEventModifierFlags mods = event.modifierFlags & DPModifiers;
    NSString *key = event.charactersIgnoringModifiers.lowercaseString;
    for (NSMenuItem *item in DPChatItems)
        if (item.keyEquivalent.length && [item.keyEquivalent.lowercaseString isEqual:key] && (item.keyEquivalentModifierMask & DPModifiers) == mods) return YES;
    // ⌃⌘Return in the command bar sends what's typed to chat.
    BOOL inBar = [NSStringFromClass([event.window.firstResponder class]) hasPrefix:@"_TtCC15BoostCommandBar"];
    return inBar && (event.keyCode == 36 || event.keyCode == 76) && mods == (NSEventModifierFlagCommand | NSEventModifierFlagControl);
}

static void DPInstallTurnOffChat(void) {
    DPHookClass(NSMenu.class, @selector(addItem:), (IMP)DPMenu_addItem);
    DPHookClass(NSMenu.class, @selector(insertItem:atIndex:), (IMP)DPMenu_insertItem);
    DPHookClass(NSMenuItem.class, @selector(setHidden:), (IMP)DPItem_setHidden);
    DPHook(DPDiaSuggestionsView, @selector(tableView:heightOfRow:), (IMP)DPSuggestions_heightOfRow);
    DPHookClass(NSTableView.class, @selector(endUpdates), (IMP)DPTable_endUpdates);
    DPHookClass(NSTableView.class, @selector(reloadData), (IMP)DPTable_reloadData);
    DPHook(DPDiaCapabilitiesToolbar, @selector(layout), (IMP)DPCapabilities_layout);
    DPHookClass(NSTableView.class, @selector(selectRowIndexes:byExtendingSelection:), (IMP)DPTable_selectRows);
    DPChatItems = [NSHashTable weakObjectsHashTable];
    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent *(NSEvent *event) {
        return DPTurnOffChat.on && DPIsChatShortcut(event) ? nil : event;
    }];
    DPOnLaunch(^{ DPTrackMenu(NSApp.mainMenu); });
}

static void DPApplyTurnOffChat(DPPatch *patch) {
    DPApplyHides(patch);
    for (NSMenuItem *item in DPChatItems.allObjects) DPTrack(item);
    for (NSView *list in DPFindViews(DPDiaSuggestionsView))
        DPFindChatRows((NSTableView *)DPFindView(list, ^BOOL(NSView *view) { return [view isKindOfClass:NSTableView.class]; }));
}

DP_PATCH(DPTurnOffChat) {
    .key = @"turnOffChat",
    .order = 88,
    .section = @"Command Bar",
    .title = @"Turn Off Chat",
    .detail = @"Hide Dia’s chat everywhere: the Chat and Chats buttons, Skills, chat menu items and their shortcuts, Chat With This Tab, and chat in the command bar. To send questions to search too, set Address Bar to Prefer Search Engine in Dia’s Advanced settings.",
    .symbol = @"bubble.left.and.exclamationmark.bubble.right.fill bubble.left.fill",
    .tint = @"systemOrangeColor",
    .hides = DPIsChatView,
    .install = DPInstallTurnOffChat,
    .apply = DPApplyTurnOffChat,
};
