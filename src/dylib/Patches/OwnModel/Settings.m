#import "Settings/Settings.h"
#import "Patches/OwnModel/OwnModel.h"

static NSString *const DPOwnModelProviderKey = @"ownModelProvider";

static NSUserDefaults *DPSettings(void) {
    static NSUserDefaults *settings;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ settings = [[NSUserDefaults alloc] initWithSuiteName:@"com.diapatches"]; });
    return settings;
}

// The effort menu: Dia's own first, then what an Anthropic endpoint takes.
static NSArray<NSArray<NSString *> *> *DPOwnModelEfforts(void) {
    return @[
        @[ @"Dia’s default", @"" ], @[ @"Off", @"off" ], @[ @"Low", @"low" ], @[ @"Medium", @"medium" ],
        @[ @"High", @"high" ], @[ @"Extra high", @"xhigh" ], @[ @"Max", @"max" ],
    ];
}

@interface DPOwnModelSettings : NSObject <NSTextFieldDelegate, NSComboBoxDelegate>
@property(nonatomic, strong) NSTextField *endpoint;
@property(nonatomic, strong) NSPopUpButton *provider;
@property(nonatomic, strong) NSComboBox *model;
@property(nonatomic, strong) NSTextField *note;
@property(nonatomic, strong) NSPopUpButton *effort;
@property(nonatomic) NSArray<NSString *> *models;
@end

@implementation DPOwnModelSettings

- (NSView *)rowFor:(NSString *)title detail:(NSTextField *)detail control:(NSView *)control {
    NSView *text = detail ? DPColumn(@[ DPLabel(title, 13, NSFontWeightRegular, NSColor.labelColor), detail ], 2)
                          : DPLabel(title, 13, NSFontWeightRegular, NSColor.labelColor);
    [text setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    NSStackView *row = [NSStackView stackViewWithViews:@[ text, control ]];
    [control setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
    return row;
}

- (NSString *)endpointValue {
    NSString *value = DPOwnModelEndpoint();
    while ([value hasSuffix:@"/"]) value = [value substringToIndex:value.length - 1];
    return value;
}

- (void)start {
    self.endpoint = [NSTextField textFieldWithString:self.endpointValue];
    self.endpoint.placeholderString = @"http://127.0.0.1:3425";
    self.endpoint.target = self;
    self.endpoint.action = @selector(endpointChanged:);
    self.endpoint.delegate = self;
    [self.endpoint.widthAnchor constraintEqualToConstant:230].active = YES;

    self.provider = [NSPopUpButton new];
    self.provider.controlSize = NSControlSizeSmall;
    self.provider.target = self;
    self.provider.action = @selector(providerChanged:);

    self.note = DPLabel(@"", 11, NSFontWeightRegular, NSColor.secondaryLabelColor);
    self.model = [NSComboBox new];
    self.model.controlSize = NSControlSizeSmall;
    self.model.numberOfVisibleItems = 14;
    self.model.completes = YES;
    self.model.target = self;
    self.model.action = @selector(modelChanged:);
    self.model.delegate = self;
    [self.model.widthAnchor constraintEqualToConstant:230].active = YES;

    self.effort = [NSPopUpButton new];
    self.effort.controlSize = NSControlSizeSmall;
    self.effort.target = self;
    self.effort.action = @selector(effortChanged:);
    for (NSArray<NSString *> *item in DPOwnModelEfforts()) {
        [self.effort addItemWithTitle:item[0]];
        self.effort.lastItem.representedObject = item[1];
    }
    [self.effort selectItemAtIndex:0];

    [self reload];
}

- (void)endpointChanged:(NSTextField *)field {
    NSString *value = [field.stringValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    while ([value hasSuffix:@"/"]) value = [value substringToIndex:value.length - 1];
    if (!value.length) {
        field.stringValue = self.endpointValue;
        return;
    }
    [DPSettings() setObject:value forKey:DPOwnModelEndpointKey];    field.stringValue = value;
    [self reload];
}

// The part of a model name before its first slash, which is what these endpoints group their models by.
- (NSString *)providerOf:(NSString *)model {
    NSRange slash = [model rangeOfString:@"/"];
    return slash.location == NSNotFound ? @"Other" : [model substringToIndex:slash.location];
}

- (NSArray<NSString *> *)providers {
    NSMutableArray<NSString *> *providers = [NSMutableArray new];
    for (NSString *model in self.models) {
        NSString *provider = [self providerOf:model];
        if (![providers containsObject:provider]) [providers addObject:provider];
    }
    return providers;
}

- (void)reload {
    self.models = @[];
    self.note.stringValue = @"Reading the model list…";
    NSString *endpoint = DPOwnModelEndpoint();
    NSURL *url = [NSURL URLWithString:[self.endpointValue stringByAppendingString:@"/v1/models"]];
    if (!url) {
        self.note.stringValue = @"That endpoint isn’t a URL.";
        return;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 10;
    NSString *token = DPOwnModelToken();
    if (token.length) [request setValue:[@"Bearer " stringByAppendingString:token] forHTTPHeaderField:@"Authorization"];
    __weak typeof(self) weak = self;
    [[NSURLSession.sharedSession dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSMutableArray<NSString *> *models = [NSMutableArray new];
            id json = data.length ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
            id list = [json isKindOfClass:NSDictionary.class] ? (json[@"data"] ?: json[@"models"]) : nil;
            if ([list isKindOfClass:NSArray.class])
                for (NSDictionary *item in list)
                    if ([item isKindOfClass:NSDictionary.class] && [item[@"id"] isKindOfClass:NSString.class])
                        [models addObject:item[@"id"]];
            dispatch_async(dispatch_get_main_queue(), ^{ [weak loaded:models endpoint:endpoint]; });
        }] resume];
}

- (void)loaded:(NSArray<NSString *> *)models endpoint:(NSString *)endpoint {
    if (![endpoint isEqual:DPOwnModelEndpoint()]) return;  // The endpoint changed while this was on its way.
    self.models = models;
    id saved = [DPSettings() objectForKey:DPOwnModelProviderKey];
    NSString *model = DPOwnModelModel();
    if (![saved isKindOfClass:NSString.class]) saved = [self providerOf:model];  // A saved "" means any provider.

    NSMenu *menu = [NSMenu new];
    [menu addItemWithTitle:models.count ? @"Any provider" : @"No provider list" action:nil keyEquivalent:@""].representedObject = @"";
    for (NSString *provider in [self providers])
        [menu addItemWithTitle:provider action:nil keyEquivalent:@""].representedObject = provider;
    self.provider.menu = menu;
    NSInteger index = [menu indexOfItemWithRepresentedObject:saved];
    [self.provider selectItemAtIndex:index >= 0 ? index : 0];

    NSMutableArray<NSString *> *shown = [NSMutableArray new];
    NSString *chosen = self.provider.selectedItem.representedObject;
    for (NSString *name in models)
        if (!chosen.length || [[self providerOf:name] isEqual:chosen]) [shown addObject:name];
    [self.model removeAllItems];
    [self.model addItemsWithObjectValues:shown];
    self.model.stringValue = model;

    NSArray<NSArray<NSString *> *> *efforts = DPOwnModelEfforts();
    NSString *effort = DPOwnModelEffort() ?: @"";
    NSUInteger selected = 0;
    for (NSUInteger i = 0; i < efforts.count; i++)
        if ([efforts[i][1] isEqual:effort]) selected = i;
    [self.effort selectItemAtIndex:selected];

    self.note.stringValue = models.count ? [NSString stringWithFormat:@"%lu models · %@", (unsigned long)models.count, endpoint]
                                         : @"Couldn’t read the model list. Type a model name, such as vendor/model.";
}

- (void)providerChanged:(NSPopUpButton *)picker {
    [DPSettings() setObject:(picker.selectedItem.representedObject ?: @"") forKey:DPOwnModelProviderKey];
    [self loaded:self.models endpoint:DPOwnModelEndpoint()];
}

- (void)modelChanged:(NSControl *)combo {
    NSString *model = [((NSComboBox *)combo).stringValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!model.length) return;
    [DPSettings() setObject:model forKey:DPOwnModelModelKey];
}

- (void)effortChanged:(NSPopUpButton *)picker {
    NSArray<NSArray<NSString *> *> *efforts = DPOwnModelEfforts();
    NSUInteger i = picker.indexOfSelectedItem;
    [DPSettings() setObject:i < efforts.count ? efforts[i][1] : @"" forKey:DPOwnModelEffortKey];
}

- (void)controlTextDidEndEditing:(NSNotification *)notification {
    id control = notification.object;
    if (control == self.endpoint) [self endpointChanged:self.endpoint];
    else if (control == self.model) [self modelChanged:self.model];
}

@end

static DPOwnModelSettings *DPOwnModelPage(void) {
    static DPOwnModelSettings *settings;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        settings = [DPOwnModelSettings new];
        [settings start];
    });
    return settings;
}

NSArray<NSView *> *DPOwnModelRows(void) {
    DPOwnModelSettings *settings = DPOwnModelPage();
    return @[
        [settings rowFor:@"Endpoint" detail:nil control:settings.endpoint],
        [settings rowFor:@"Provider" detail:nil control:settings.provider],
        [settings rowFor:@"Model" detail:settings.note control:settings.model],
        [settings rowFor:@"Thinking" detail:nil control:settings.effort],
    ];
}
