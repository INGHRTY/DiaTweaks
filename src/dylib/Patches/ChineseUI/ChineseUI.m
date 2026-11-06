#import "StdPatch/StdPatch.h"

extern DPPatch DPChineseUI;

NSDictionary<NSString *, NSString *> *DPChineseStrings(void);

// Other patches find Dia's menus by their English titles; this lets them match the translated ones too.
NSString *DPTranslatedTitle(NSString *english) {
    return english ? DPChineseStrings()[english] : nil;
}

static NSString *DPTranslated(NSString *text) {
    if (!DPChineseUI.on || text.length < 2) return text;
    return DPChineseStrings()[text] ?: text;
}

// The dictionary maps one English string to one Chinese string, so a Chinese string leads back to its English one.
static NSString *DPUntranslated(NSString *text) {
    if (text.length < 2) return text;
    for (NSString *english in DPChineseStrings())
        if ([DPChineseStrings()[english] isEqualToString:text]) return english;
    return text;
}

#pragma mark - AppKit

static void DPTextField_setStringValue(NSTextField *self, SEL _cmd, NSString *value) {
    DPCallOriginal(DPTextField_setStringValue, self, self.isEditable ? value : DPTranslated(value));
}

static void DPTextField_setAttributedStringValue(NSTextField *self, SEL _cmd, NSAttributedString *value) {
    NSString *translated = self.isEditable || !DPChineseUI.on ? nil : DPChineseStrings()[value.string];
    if (!translated) return DPCallOriginal(DPTextField_setAttributedStringValue, self, value);
    NSMutableAttributedString *copy = [value mutableCopy];
    [copy replaceCharactersInRange:NSMakeRange(0, copy.length) withString:translated];
    DPCallOriginal(DPTextField_setAttributedStringValue, self, copy);
}

static void DPTextFieldCell_setStringValue(NSTextFieldCell *self, SEL _cmd, NSString *value) {
    DPCallOriginal(DPTextFieldCell_setStringValue, self, self.isEditable ? value : DPTranslated(value));
}

static void DPButton_setTitle(NSButton *self, SEL _cmd, NSString *title) {
    DPCallOriginal(DPButton_setTitle, self, DPTranslated(title));
}

static void DPMenuItem_setTitle(NSMenuItem *self, SEL _cmd, NSString *title) {
    DPCallOriginal(DPMenuItem_setTitle, self, DPTranslated(title));
}

static id DPMenuItem_initWithTitle(NSMenuItem *self, SEL _cmd, NSString *title, SEL action, NSString *key) {
    return DPCallOriginal(DPMenuItem_initWithTitle, self, DPTranslated(title), action, key);
}

static void DPTabViewItem_setLabel(NSTabViewItem *self, SEL _cmd, NSString *label) {
    DPCallOriginal(DPTabViewItem_setLabel, self, DPTranslated(label));
}

static void DPToolbarItem_setLabel(NSToolbarItem *self, SEL _cmd, NSString *label) {
    DPCallOriginal(DPToolbarItem_setLabel, self, DPTranslated(label));
}

static void DPSegmentedControl_setLabel(NSSegmentedControl *self, SEL _cmd, NSString *label, NSInteger segment) {
    DPCallOriginal(DPSegmentedControl_setLabel, self, DPTranslated(label), segment);
}

#pragma mark - Turning it on and off

static void DPTranslateView(NSView *view, BOOL on) {
    if ([view isKindOfClass:NSTextField.class] && ![(NSTextField *)view isEditable]) {
        NSTextField *field = (NSTextField *)view;
        NSString *text = field.stringValue, *changed = on ? DPTranslated(text) : DPUntranslated(text);
        if (![changed isEqualToString:text]) field.stringValue = changed;
    } else if ([view isKindOfClass:NSButton.class]) {
        NSButton *button = (NSButton *)view;
        NSString *changed = on ? DPTranslated(button.title) : DPUntranslated(button.title);
        if (![changed isEqualToString:button.title]) button.title = changed;
    }
    for (NSView *subview in view.subviews) DPTranslateView(subview, on);
}

static void DPTranslateItem(NSMenuItem *item, BOOL on) {
    NSString *changed = on ? DPTranslated(item.title) : DPUntranslated(item.title);
    if (![changed isEqualToString:item.title]) item.title = changed;
    for (NSMenuItem *subitem in item.submenu.itemArray) DPTranslateItem(subitem, on);
}

static void DPApplyChineseUI(DPPatch *patch) {
    BOOL on = patch->on;
    for (NSWindow *window in NSApp.windows) DPTranslateView(window.contentView, on);
    NSMenu *mainMenu = NSApp.mainMenu;
    for (NSMenuItem *item in mainMenu.itemArray) DPTranslateItem(item, on);
}

#pragma mark - Dev tools

static NSMenuItem *DPMenuBarItem(NSString *title) {
    for (NSMenuItem *item in NSApp.mainMenu.itemArray)
        if ([item.title isEqualToString:title]) return item;
    return nil;
}

// With devTools on, writes every menu title to menus.txt beside the dylib, in English, to find what to translate.
// Post com.diapatches.dev.menus to write it again, such as after flipping the patch.
static void DPDumpMenus(void) {
    if (![[[NSUserDefaults alloc] initWithSuiteName:@"com.diapatches"] boolForKey:@"devTools"]) return;
    void (^write)(void) = ^{
        NSMutableString *out = [NSMutableString new];
        for (NSMenuItem *top in NSApp.mainMenu.itemArray) {
            [out appendFormat:@"%@ | %@\n", DPUntranslated(top.title), top.title];
            for (NSMenuItem *item in top.submenu.itemArray)
                if (!item.isSeparatorItem) [out appendFormat:@"  %@ | %@\n", DPUntranslated(item.title), item.title];
        }
        [out writeToFile:DPAppSupport(@"DiaPatches/menus.txt") atomically:YES encoding:NSUTF8StringEncoding error:nil];
    };
    DPOnLaunch(write);
    [NSDistributedNotificationCenter.defaultCenter addObserverForName:@"com.diapatches.dev.menus" object:nil
                                                                queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *_) { write(); }];
}

static void DPInstallChineseUI(void) {
    DPHook("NSTextField", @selector(setStringValue:), (IMP)DPTextField_setStringValue);
    DPHook("NSTextField", @selector(setAttributedStringValue:), (IMP)DPTextField_setAttributedStringValue);
    DPHook("NSTextFieldCell", @selector(setStringValue:), (IMP)DPTextFieldCell_setStringValue);
    DPHook("NSButton", @selector(setTitle:), (IMP)DPButton_setTitle);
    DPHook("NSMenuItem", @selector(setTitle:), (IMP)DPMenuItem_setTitle);
    DPHook("NSMenuItem", @selector(initWithTitle:action:keyEquivalent:), (IMP)DPMenuItem_initWithTitle);
    DPHook("NSTabViewItem", @selector(setLabel:), (IMP)DPTabViewItem_setLabel);
    DPHook("NSToolbarItem", @selector(setLabel:), (IMP)DPToolbarItem_setLabel);
    DPHook("NSSegmentedControl", @selector(setLabel:forSegment:), (IMP)DPSegmentedControl_setLabel);
    DPDumpMenus();
}

static NSString *DPVerifyChineseUI(DPPatch *patch) {
    BOOL translated = DPMenuBarItem(@"文件") != nil;
    if (translated == patch->on) return nil;
    return patch->on ? @"the File menu is still in English" : @"the File menu is still in Chinese";
}

DP_PATCH(DPChineseUI) {
    .key = @"chineseUI",
    .defaultOn = YES,
    .title = @"Chinese Interface",
    .detail = @"Translate Dia's interface into Chinese. The command bar, web pages and text fields are left alone.",
    .symbol = @"character.bubble.fill",
    .tint = @"systemBlueColor",
    .section = @"Language",
    .install = DPInstallChineseUI,
    .apply = DPApplyChineseUI,
    .verify = DPVerifyChineseUI,
};
