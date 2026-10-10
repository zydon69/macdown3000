#import <XCTest/XCTest.h>
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "MPDocument.h"
#import "MPEditorView.h"
#import "MPRenderer.h"
#import "MPPreferences.h"

@interface MPPreferences (FormattingScopeMenuTests)
- (int)rendererFlags;
@end

@interface MPDocument (FormattingScopeMenuTests)
@property (strong) MPRenderer *renderer;
@property (weak) MPEditorView *editor;
@property (weak) WebView *preview;
@property (nonatomic) BOOL alreadyRenderingInWeb;
@property (copy) NSString *previewEditSource;
@property (copy) NSString *previewEditToken;
@property (copy) NSArray<NSDictionary *> *previewEditRanges;
- (IBAction)convertToH1:(id)sender;
- (IBAction)toggleStrong:(id)sender;
- (IBAction)toggleLink:(id)sender;
- (BOOL)previewHasFindFocus;
@end

// Exercise rendered selections, the JavaScript controls and native formatting
// transactions together. The matrix tests cover the full conversion product;
// these tests prove that the menus expose those independent scopes correctly.
@interface MPFormattingScopeMenuTests : XCTestCase
@property (strong) MPDocument *document;
@property (strong) MPEditorView *editor;
@property (strong) WebView *web;
@property (strong) NSWindow *window;
@property (strong) MPRenderer *renderer;
@property (copy) NSDictionary<NSString *, NSNumber *> *savedPreferences;
@property (copy) NSString *savedStyleName;
@property (strong) NSURL *fixtureDirectory;
@end

@implementation MPFormattingScopeMenuTests

- (void)setUp
{
    [super setUp];
    self.fixtureDirectory=[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString] isDirectory:YES];
    XCTAssertTrue([NSFileManager.defaultManager createDirectoryAtURL:self.fixtureDirectory withIntermediateDirectories:YES attributes:nil error:NULL]);
    self.document=[MPDocument new];
    self.document.fileURL=[self.fixtureDirectory URLByAppendingPathComponent:@"scopes.md"];
    self.editor=[[MPEditorView alloc] initWithFrame:NSMakeRect(0,0,600,450)];
    self.web=[[WebView alloc] initWithFrame:NSMakeRect(600,0,600,450)];
    self.window=[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,1200,450) styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
    self.window.releasedWhenClosed=NO;
    [self.window.contentView addSubview:self.editor];
    [self.window.contentView addSubview:self.web];
    self.renderer=[MPRenderer new];
    self.document.editor=self.editor; self.document.preview=self.web; self.document.renderer=self.renderer;
    self.renderer.delegate=(id<MPRendererDelegate>)self.document;
    self.renderer.dataSource=(id<MPRendererDataSource>)self.document;
    self.web.frameLoadDelegate=(id<WebFrameLoadDelegate>)self.document;
    self.web.policyDelegate=(id<WebPolicyDelegate>)self.document;
    self.web.editingDelegate=(id<WebEditingDelegate>)self.document;
    self.savedStyleName=self.document.preferences.htmlStyleName;
    // Keep resource loading local and independent of another suite's theme.
    self.document.preferences.htmlStyleName=@"GitHub2";
    NSDictionary *settings=@{@"htmlMathJax":@NO,@"extensionSmartyPants":@NO,@"htmlSyntaxHighlighting":@NO,
        @"htmlMermaid":@NO,@"htmlGraphviz":@NO,@"htmlTaskList":@YES,@"extensionFencedCode":@YES,
        @"extensionIntraEmphasis":@YES,@"extensionUnderline":@YES,@"extensionStrikethough":@YES};
    NSMutableDictionary *saved=[NSMutableDictionary dictionary];
    for (NSString *key in settings) {
        saved[key]=[self.document.preferences valueForKey:key];
        [self.document.preferences setValue:settings[key] forKey:key];
    }
    self.savedPreferences=saved;
    self.renderer.rendererFlags=self.document.preferences.rendererFlags;
}

- (void)tearDown
{
    self.web.frameLoadDelegate=nil; self.web.policyDelegate=nil; self.web.editingDelegate=nil;
    self.window.contentView=nil; [self.window close];
    [self.document close];
    for (NSString *key in self.savedPreferences) [self.document.preferences setValue:self.savedPreferences[key] forKey:key];
    self.document.preferences.htmlStyleName=self.savedStyleName;
    [NSFileManager.defaultManager removeItemAtURL:self.fixtureDirectory error:NULL];
    self.renderer=nil; self.document=nil; self.editor=nil; self.web=nil; self.window=nil;
    [super tearDown];
}

- (void)waitUntil:(BOOL (^)(void))condition description:(NSString *)description
{
    XCTNSPredicateExpectation *expectation=[[XCTNSPredicateExpectation alloc] initWithPredicate:
        [NSPredicate predicateWithBlock:^BOOL(id object,NSDictionary *bindings){return condition();}] object:self.web];
    XCTWaiterResult result=[XCTWaiter waitForExpectations:@[expectation] timeout:10];
    if (result!=XCTWaiterResultCompleted) {
        NSString *state=[self JS:@"JSON.stringify({selection:getSelection().toString(),payload:window.macdownPreviewEditor&&macdownPreviewEditor.selectionPayload('bold'),panel:document.getElementById('macdown-preview-format')&&getComputedStyle(document.getElementById('macdown-preview-format')).display,menus:Array.from(document.querySelectorAll('#macdown-preview-format select')).map(function(s){return {scope:s.getAttribute('data-mp-scope'),value:s.value,active:s.hasAttribute('data-mp-active')};})})"];
        XCTFail(@"%@ timed out after 10 seconds; loading=%d rendering=%d mapped=%lu sourceCurrent=%d previewToken=%@ rendererToken=%@ pending=%@ DOM=%@",description,self.web.isLoading,self.document.alreadyRenderingInWeb,(unsigned long)self.document.previewEditRanges.count,[self.document.previewEditSource isEqualToString:self.editor.string],self.document.previewEditToken,self.renderer.checkboxBridgeToken,[self.document valueForKey:@"renderToWebPending"],state);
    }
}

- (NSString *)JS:(NSString *)script
{
    return [self.web stringByEvaluatingJavaScriptFromString:script];
}

- (void)loadSource:(NSString *)source
{
    // Establish the window before selecting: activating a previously hidden
    // WebView window can clear its DOM selection as it changes responder.
    [self.window makeKeyAndOrderFront:nil];
    self.editor.string=source;
    // Preferences can already have scheduled an asynchronous parse. Use the
    // application's public entry point to supersede it; a private synchronous
    // parse would leave that older generation free to publish stale identities.
    [self.renderer parseAndRenderNow];
    [self waitUntil:^BOOL{
        return !self.web.isLoading && !self.document.alreadyRenderingInWeb &&
            [self.document.previewEditSource isEqualToString:source] &&
            [self.document.previewEditToken isEqualToString:self.renderer.checkboxBridgeToken] &&
            self.document.previewEditRanges.count>0;
    } description:@"Load document and install preview mapping"];
    XCTAssertTrue([self.window makeFirstResponder:self.web]);
}

- (void)waitForFormatting
{
    [self waitUntil:^BOOL{
        return !self.web.isLoading && !self.document.alreadyRenderingInWeb &&
            [self.document.previewEditSource isEqualToString:self.editor.string] &&
            ![self.document valueForKey:@"previewSelectionToRestore"] &&
            ![[self.document valueForKey:@"previewQueuedFormatting"] count];
    } description:@"Finish formatting and restore selection"];
}

- (void)selectFromText:(NSString *)first throughText:(NSString *)last
{
    NSData *JSON=[NSJSONSerialization dataWithJSONObject:@[first,last] options:0 error:NULL];
    NSString *arguments=[[NSString alloc] initWithData:JSON encoding:NSUTF8StringEncoding];
    NSString *script=[NSString stringWithFormat:
        @"(function(){var text=%@,nodes=macdownPreviewEditor.elements().spans,a=nodes.find(function(n){return n.textContent===text[0];}),b=nodes.find(function(n){return n.textContent===text[1];});if(!a||!b)return false;a.dispatchEvent(new MouseEvent('mousedown',{bubbles:true,button:0}));var r=document.createRange();r.setStart(a.firstChild,0);r.setEnd(b.firstChild,b.textContent.length);getSelection().removeAllRanges();getSelection().addRange(r);window.dispatchEvent(new MouseEvent('mouseup',{bubbles:true,button:0}));return true;})()",arguments];
    XCTAssertTrue([[self JS:script] boolValue],@"Mapped selection %@ through %@ must exist",first,last);
    [self waitUntil:^BOOL{return [[self JS:@"getComputedStyle(document.getElementById('macdown-preview-format')).display"] isEqualToString:@"block"];} description:[NSString stringWithFormat:@"Show panel for selection %@ through %@",first,last]];
}

- (void)assertMenuScope:(NSString *)scope value:(NSString *)value active:(BOOL)active
{
    NSString *selector=[NSString stringWithFormat:@"document.querySelector('[data-mp-scope=\"%@\"] [data-mp-option=\"%@\"]')",scope,value];
    if (!value.length) {
        XCTAssertEqualObjects(([self JS:[NSString stringWithFormat:@"String(document.querySelectorAll('[data-mp-scope=\"%@\"] [data-mp-active]').length)",scope]]),@"0");
        return;
    }
    XCTAssertEqual([[self JS:[selector stringByAppendingString:@".hasAttribute('data-mp-active')"]] boolValue],active);
    XCTAssertEqualObjects([self JS:[selector stringByAppendingString:@".getAttribute('aria-checked')"]],active ? @"true" : @"false");
    if (active) XCTAssertEqualObjects(([self JS:[NSString stringWithFormat:@"getComputedStyle(%@).color",selector]]),@"rgb(39, 132, 222)");
}

- (void)chooseContainer:(NSString *)value
{
    [self JS:[NSString stringWithFormat:@"(function(){document.querySelector('[data-mp-format-menu]').click();document.querySelector('[data-mp-scope=container] [data-mp-option=\"%@\"]').click();})()",value]];
}

- (NSArray<NSView *> *)allSubviewsOf:(NSView *)view
{
    NSMutableArray *views=[NSMutableArray array];
    for (NSView *child in view.subviews) {
        [views addObject:child];
        [views addObjectsFromArray:[self allSubviewsOf:child]];
    }
    return views;
}

// Drive NSAlert's native controls inside its modal run loop. A bounded callback
// aborts only this test's modal session if the expected controls never appear;
// no Accessibility or UI-automation permission is required.
- (void)invokeLinkWithAddress:(NSString *)address apply:(BOOL)apply
{
    XCTAssertTrue([self.document previewHasFindFocus]);
    XCTAssertTrue([[self JS:@"Boolean(macdownPreviewEditor.selectionPayload('link'))"] boolValue]);
    __block BOOL answered=NO,finished=NO;
    __block NSString *modalDescription=@"No modal observed";
    __block NSUInteger attempts=0;
    __block void (^respond)(void);
    respond=^{
        if (finished) {respond=nil;return;}
        NSWindow *modal=NSApp.modalWindow;
        NSTextField *field=nil;
        NSButton *button=nil;
        NSMutableArray *controls=[NSMutableArray array];
        for (NSView *view in [self allSubviewsOf:modal.contentView]) {
            if ([view isKindOfClass:NSButton.class]) [controls addObject:[NSString stringWithFormat:@"button %@ tag %ld",[(NSButton *)view title],(long)view.tag]];
            if ([view isKindOfClass:NSTextField.class] && [(NSTextField *)view isEditable]) [controls addObject:[NSString stringWithFormat:@"editable field %@",[(NSTextField *)view stringValue]]];
            if ([view isKindOfClass:NSTextField.class] && [(NSTextField *)view isEditable] &&
                [[(NSTextField *)view stringValue] isEqualToString:@"https://"]) field=(NSTextField *)view;
            if ([view isKindOfClass:NSButton.class] && view.tag==(apply ? NSAlertFirstButtonReturn : NSAlertSecondButtonReturn)) button=(NSButton *)view;
        }
        if (modal) modalDescription=[controls componentsJoinedByString:@"; "];
        if (field && button) {
            field.stringValue=address;
            answered=YES; finished=YES;
            [button performClick:nil];
            respond=nil;
        } else if (++attempts>=40) {
            finished=YES;
            if (NSApp.modalWindow) [NSApp abortModal];
            respond=nil;
        } else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.05*NSEC_PER_SEC)),dispatch_get_main_queue(),respond);
        }
    };
    dispatch_async(dispatch_get_main_queue(),respond);
    XCTAssertTrue([NSApp sendAction:@selector(toggleLink:) to:self.document from:nil]);
    finished=YES; respond=nil;
    XCTAssertTrue(answered,@"Expected link address field and %@ button must be available; %@",apply ? @"Apply" : @"Cancel",modalDescription);
}

- (void)testNativeLinkActionPreservesHeadingContainerSelectionAndRejectsCancelOrUnsafeURLAtomically
{
    NSString *source=@"::: {.callout-note}\n## Title\n# **Heading**\n\nBody\n:::\n\nNeighbor.\n";
    [self loadSource:source];
    [self selectFromText:@"Heading" throughText:@"Heading"];
    [self invokeLinkWithAddress:@"https://example.com/scopes" apply:NO];
    XCTAssertEqualObjects(self.editor.string,source,@"Cancel must not create a Markdown link");
    XCTAssertEqualObjects([self JS:@"getSelection().toString()"],@"Heading");
    [self invokeLinkWithAddress:@"javascript:alert(1)" apply:YES];
    XCTAssertEqualObjects(self.editor.string,source,@"An unsafe URL must leave every scope unchanged");
    XCTAssertFalse([[self JS:@"!!document.querySelector('h1 a')"] boolValue]);
    XCTAssertEqualObjects([self JS:@"getSelection().toString()"],@"Heading");
    [self invokeLinkWithAddress:@"https://example.com/scopes" apply:YES];
    [self waitUntil:^BOOL{return [self.editor.string containsString:@"https://example.com/scopes"];} description:@"Native link action creates source Markdown"];
    [self waitForFormatting];
    XCTAssertFalse([self.editor.string containsString:@"<a"]);
    XCTAssertTrue([self.editor.string containsString:@"](https://example.com/scopes)"] ||
        [self.editor.string containsString:@"](<https://example.com/scopes>)"]);
    XCTAssertTrue([self.editor.string containsString:@"::: {.callout-note}"]);
    XCTAssertTrue([self.editor.string containsString:@"## Title"]);
    XCTAssertTrue([self.editor.string containsString:@"Body"]);
    XCTAssertTrue([self.editor.string hasSuffix:@"\nNeighbor.\n"]);
    XCTAssertEqualObjects([self JS:@"document.querySelector('h1 a').getAttribute('href')"],@"https://example.com/scopes");
    XCTAssertEqualObjects([self JS:@"document.querySelector('h1 a').textContent"],@"Heading");
    XCTAssertTrue([[self JS:@"!!document.querySelector('h1 strong')"] boolValue]);
    XCTAssertEqualObjects([self JS:@"getSelection().toString()"],@"Heading");
    [self assertMenuScope:@"block" value:@"h1" active:YES];
    [self assertMenuScope:@"container" value:@"callout-note" active:YES];
    XCTAssertEqualObjects([self JS:@"document.querySelector('[data-mp-style=link]').getAttribute('aria-pressed')"],@"true");
}

- (void)testTextDropdownHasSeparatedScopesAndInlineIconsKeepTooltips
{
    [self loadSource:@"# **Heading**\n\nBody\n"];
    [self selectFromText:@"Heading" throughText:@"Heading"];
    XCTAssertEqualObjects([self JS:@"String(document.querySelectorAll('#macdown-preview-format select').length)"],@"0");
    XCTAssertEqualObjects([self JS:@"String(document.querySelectorAll('#macdown-preview-format [role=separator]').length)"],@"1");
    XCTAssertTrue([[self JS:@"Array.from(document.querySelectorAll('#macdown-preview-format > [data-mp-inline],#macdown-preview-format > [data-mp-edit-text]')).every(function(b){return b.querySelector('svg') && b.title && b.getAttribute('aria-label')===b.title && !Array.from(b.childNodes).some(function(n){return n.nodeType===3 && n.textContent.trim();});})"] boolValue]);
    XCTAssertTrue([[self JS:@"Array.from(document.querySelectorAll('[data-mp-option]')).every(function(b){return b.querySelector('span').textContent===b.getAttribute('aria-label');})"] boolValue]);
    XCTAssertEqualObjects([self JS:@"document.querySelector('[data-mp-format-menu]').textContent"],@"Titre 1 ▾");
    XCTAssertTrue([[self JS:@"document.querySelector('[role=menu]').hidden"] boolValue]);
    [self JS:@"document.querySelector('[data-mp-format-menu]').click()"];
    XCTAssertFalse([[self JS:@"document.querySelector('[role=menu]').hidden"] boolValue]);
    XCTAssertTrue([[self JS:@"(function(){var r=document.querySelector('#macdown-preview-format').getBoundingClientRect();return r.top>=0 && r.bottom<=innerHeight;})()"] boolValue]);
    [self assertMenuScope:@"block" value:@"h1" active:YES];
    [self assertMenuScope:@"container" value:@"no-container" active:YES];
    XCTAssertEqualObjects([self JS:@"getSelection().toString()"],@"Heading");
    [self JS:@"document.querySelector('[data-mp-format-menu]').dispatchEvent(new KeyboardEvent('keydown',{key:'ArrowDown',bubbles:true}))"];
    XCTAssertEqualObjects([self JS:@"document.activeElement.getAttribute('data-mp-option')"],@"paragraph");
    [self JS:@"document.activeElement.dispatchEvent(new KeyboardEvent('keydown',{key:'ArrowRight',bubbles:true}))"];
    XCTAssertEqualObjects([self JS:@"document.activeElement.getAttribute('data-mp-option')"],@"h1");
    [self JS:@"document.activeElement.dispatchEvent(new KeyboardEvent('keydown',{key:'Escape',bubbles:true}))"];
    XCTAssertTrue([[self JS:@"document.querySelector('[role=menu]').hidden"] boolValue]);
    XCTAssertTrue([[self JS:@"document.activeElement.hasAttribute('data-mp-format-menu')"] boolValue]);
    XCTAssertEqualObjects(self.editor.string,@"# **Heading**\n\nBody\n");
    [self JS:@"document.querySelector('[data-mp-format-menu]').click();document.querySelector('[data-mp-option=h2]').click()"];
    [self waitForFormatting];
    XCTAssertEqualObjects(self.editor.string,@"## **Heading**\n\nBody\n");
    XCTAssertEqualObjects([self JS:@"getSelection().toString()"],@"Heading");
    [self assertMenuScope:@"block" value:@"h2" active:YES];
    [self assertMenuScope:@"container" value:@"no-container" active:YES];
}

- (void)testHeadingAndContainerAreIndependentAndMixedBlocksKeepOnlyTheirCommonContainer
{
    [self loadSource:@"::: {.callout-note}\n## Title\n# **Heading**\n\nBody\n:::\n\nNeighbor.\n"];
    [self selectFromText:@"Heading" throughText:@"Heading"];
    XCTAssertEqualObjects([self JS:@"String(document.querySelectorAll('#macdown-preview-format [data-mp-format-menu]').length)"],@"1");
    [self assertMenuScope:@"block" value:@"h1" active:YES];
    [self assertMenuScope:@"container" value:@"callout-note" active:YES];
    XCTAssertEqualObjects([self JS:@"document.querySelector('[data-mp-style=bold]').getAttribute('aria-pressed')"],@"true");
    [self selectFromText:@"Heading" throughText:@"Body"];
    [self assertMenuScope:@"block" value:@"" active:NO];
    [self assertMenuScope:@"container" value:@"callout-note" active:YES];
    XCTAssertEqualObjects([self JS:@"document.querySelector('[data-mp-style=bold]').getAttribute('aria-pressed')"],@"false");
    [self selectFromText:@"Heading" throughText:@"Neighbor."];
    [self assertMenuScope:@"block" value:@"" active:NO];
    [self assertMenuScope:@"container" value:@"" active:NO];
    XCTAssertEqualObjects(self.editor.string,@"::: {.callout-note}\n## Title\n# **Heading**\n\nBody\n:::\n\nNeighbor.\n");
}

- (void)testFreshPreviewPressClearsOnlyUnmodifiedSingleClickSelections
{
    for (NSString *prefix in @[@"",@"> ",@"# "]) {
        NSString *source=[NSString stringWithFormat:@"%@Plainword [Linkword](https://example.com) **Boldword**\n\nNeighbor.\n",prefix];
        [self loadSource:source];
        NSArray *gestures=@[
            @{@"name":@"fresh press",@"options":@{@"detail":@1},@"target":@"plain",@"retained":@NO},
            @{@"name":@"double click",@"options":@{@"detail":@2},@"target":@"plain",@"retained":@YES},
            @{@"name":@"triple click",@"options":@{@"detail":@3},@"target":@"plain",@"retained":@YES},
            @{@"name":@"shift extension",@"options":@{@"detail":@1,@"shiftKey":@YES},@"target":@"plain",@"retained":@YES},
            @{@"name":@"command gesture",@"options":@{@"detail":@1,@"metaKey":@YES},@"target":@"plain",@"retained":@YES},
            @{@"name":@"control gesture",@"options":@{@"detail":@1,@"ctrlKey":@YES},@"target":@"plain",@"retained":@YES},
            @{@"name":@"option gesture",@"options":@{@"detail":@1,@"altKey":@YES},@"target":@"plain",@"retained":@YES},
            @{@"name":@"context menu",@"options":@{@"detail":@1,@"button":@2},@"target":@"plain",@"retained":@YES},
            @{@"name":@"link activation",@"options":@{@"detail":@1},@"target":@"link",@"retained":@YES},
            @{@"name":@"formatting control",@"options":@{@"detail":@1},@"target":@"button",@"retained":@YES},
            @{@"name":@"unmapped content",@"options":@{@"detail":@1},@"target":@"body",@"retained":@YES}
        ];
        for (NSDictionary *gesture in gestures) {
            NSData *data=[NSJSONSerialization dataWithJSONObject:gesture options:0 error:NULL];
            NSString *arguments=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSString *result=[self JS:[NSString stringWithFormat:
                @"(function(){var g=%@,nodes=macdownPreviewEditor.elements().spans,p=nodes.find(function(n){return n.textContent==='Plainword ';}),link=nodes.find(function(n){return n.textContent==='Linkword';});if(!p||!link)return 'missing mapped fixture';var r=document.createRange();r.setStart(p.firstChild,0);r.setEnd(p.firstChild,9);getSelection().removeAllRanges();getSelection().addRange(r);var targets={plain:p,link:link,button:document.querySelector('[data-mp-style=bold]'),body:document.body};targets[g.target].dispatchEvent(new MouseEvent('mousedown',Object.assign({bubbles:true,button:0},g.options)));var selected=getSelection().toString();window.dispatchEvent(new MouseEvent('mouseup',{bubbles:true,button:0}));return selected;})()",arguments]];
            XCTAssertEqualObjects(result,[gesture[@"retained"] boolValue]?@"Plainword":@"",@"%@ %@",prefix,gesture[@"name"]);
            XCTAssertEqualObjects(self.editor.string,source);
        }
        // Explicit text editing owns its range, even during a single press.
        [self selectFromText:@"Plainword " throughText:@"Plainword "];
        [self JS:@"document.querySelector('[data-mp-edit-text]').click()"];
        XCTAssertEqualObjects([self JS:@"(function(){var p=document.querySelector('[contenteditable=true]');if(!p)return 'missing active edit';p.dispatchEvent(new MouseEvent('mousedown',{bubbles:true,button:0,detail:1}));var text=getSelection().toString();window.dispatchEvent(new MouseEvent('mouseup',{bubbles:true,button:0}));p.dispatchEvent(new KeyboardEvent('keydown',{bubbles:true,key:'Escape'}));return text;})()"],@"Plainword ");
        [self waitForFormatting];
        XCTAssertEqualObjects(self.editor.string,source);
    }
}

- (void)testInlineCodeAndEmphasisCanCoexistWhileFencedCodeKeepsStructuralMenus
{
    [self loadSource:@"::: {.callout-tip}\n## Title\n# **`Inline`**\n\n```\nLiteral\n```\n:::\n"];
    [self selectFromText:@"Inline" throughText:@"Inline"];
    [self assertMenuScope:@"block" value:@"h1" active:YES];
    [self assertMenuScope:@"container" value:@"callout-tip" active:YES];
    for (NSString *style in @[@"bold",@"code"]) {
        XCTAssertEqualObjects(([self JS:[NSString stringWithFormat:@"document.querySelector('[data-mp-style=%@]').getAttribute('aria-pressed')",style]]),@"true");
    }
    for (NSString *style in @[@"bold",@"italic",@"underline",@"strike",@"link",@"code"]) {
        XCTAssertFalse(([[self JS:[NSString stringWithFormat:@"document.querySelector('[data-mp-style=%@]').disabled",style]] boolValue]));
    }
    // The native endpoint must write the style outside the backticks and keep
    // the rendered selection instead of exposing literal Markdown markers.
    XCTAssertTrue([NSApp sendAction:@selector(toggleStrong:) to:self.document from:nil]);
    [self waitForFormatting];
    XCTAssertTrue([self.editor.string containsString:@"# `Inline`"]);
    XCTAssertEqualObjects([self JS:@"getSelection().toString()"],@"Inline");
    XCTAssertTrue([NSApp sendAction:@selector(toggleStrong:) to:self.document from:nil]);
    [self waitForFormatting];
    XCTAssertTrue([self.editor.string containsString:@"# **`Inline`**"]);
    [self selectFromText:@"Literal" throughText:@"Literal"];
    [self assertMenuScope:@"block" value:@"code-block" active:YES];
    [self assertMenuScope:@"container" value:@"callout-tip" active:YES];
    XCTAssertTrue([[self JS:@"Array.from(document.querySelectorAll('#macdown-preview-format [data-mp-inline],#macdown-preview-format [data-mp-edit-text]')).every(function(b){return b.disabled;})"] boolValue]);
    XCTAssertTrue([[self JS:@"!document.querySelector('[data-mp-format-menu]').disabled && !document.querySelector('[data-mp-option=paragraph]').disabled"] boolValue]);
}

- (void)testRemovingContainerViaItsMenuPreservesTitleBodyHeadingAndInlineStyle
{
    [self loadSource:@"::: {.callout-warning}\n## Title\n# **Heading**\n\nBody\n:::\n\nNeighbor.\n"];
    [self selectFromText:@"Heading" throughText:@"Heading"];
    [self chooseContainer:@"no-container"];
    [self waitUntil:^BOOL{return ![self.editor.string containsString:@":::"];} description:@"Container menu removes callout envelope"];
    [self waitForFormatting];
    XCTAssertTrue([self.editor.string containsString:@"## Title"]);
    XCTAssertTrue([self.editor.string containsString:@"# **Heading**"]);
    XCTAssertTrue([self.editor.string containsString:@"Body"]);
    XCTAssertTrue([self.editor.string hasSuffix:@"\nNeighbor.\n"]);
    XCTAssertEqualObjects([self JS:@"getSelection().toString()"],@"Heading");
    [self assertMenuScope:@"block" value:@"h1" active:YES];
    [self assertMenuScope:@"container" value:@"no-container" active:YES];
    XCTAssertEqualObjects([self JS:@"document.querySelector('[data-mp-style=bold]').getAttribute('aria-pressed')"],@"true");
    XCTAssertFalse([[self JS:@"!!document.querySelector('.mp-callout')"] boolValue]);
    XCTAssertEqualObjects([self JS:@"document.querySelector('h1').textContent"],@"Heading");
}

- (void)testRapidQueuedBlockAndInlineFormattingPreservesContainerSelectionAndDisclosure
{
    [self loadSource:@"::: {.callout-note collapse=\"true\"}\n## Title\nBody\n:::\n\nNeighbor.\n"];
    [self JS:@"document.querySelector('details').open=true"];
    [self selectFromText:@"Body" throughText:@"Body"];
    // Invoke the actual quick-toolbar actions without yielding to WebKit.
    // The second action must queue against the first action's pending render.
    XCTAssertTrue([NSApp sendAction:@selector(convertToH1:) to:self.document from:nil]);
    XCTAssertNotNil([self.document valueForKey:@"previewSelectionToRestore"]);
    XCTAssertTrue([NSApp sendAction:@selector(toggleStrong:) to:self.document from:nil]);
    XCTAssertEqual([[self.document valueForKey:@"previewQueuedFormatting"] count],1u);
    [self waitForFormatting];
    XCTAssertTrue([self.editor.string containsString:@"::: {.callout-note collapse=\"true\"}"]);
    XCTAssertTrue([self.editor.string containsString:@"## Title"]);
    XCTAssertTrue([self.editor.string containsString:@"# **Body**"]);
    XCTAssertTrue([self.editor.string hasSuffix:@"\nNeighbor.\n"]);
    XCTAssertEqualObjects([self JS:@"getSelection().toString()"],@"Body");
    XCTAssertEqualObjects([self JS:@"String(document.querySelector('details').open)"],@"true");
    [self assertMenuScope:@"block" value:@"h1" active:YES];
    [self assertMenuScope:@"container" value:@"toggle-h2" active:YES];
    XCTAssertEqualObjects([self JS:@"document.querySelector('[data-mp-style=bold]').getAttribute('aria-pressed')"],@"true");
    XCTAssertEqualObjects([self JS:@"document.querySelector('details .mp-callout-body h1 strong').textContent"],@"Body");
}

@end
