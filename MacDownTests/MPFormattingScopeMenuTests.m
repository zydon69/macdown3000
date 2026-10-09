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
    NSString *selector=[NSString stringWithFormat:@"document.querySelector('#macdown-preview-format select[data-mp-scope=\"%@\"]')",scope];
    XCTAssertEqualObjects([self JS:[selector stringByAppendingString:@".value"]],value);
    XCTAssertEqual([[self JS:[selector stringByAppendingString:@".hasAttribute('data-mp-active')"]] boolValue],active);
    if (active) {
        XCTAssertEqualObjects(([self JS:[NSString stringWithFormat:@"getComputedStyle(%@).color",selector]]),@"rgb(39, 132, 222)");
        XCTAssertTrue([[self JS:[selector stringByAppendingString:@".selectedOptions[0].hasAttribute('data-mp-active')"]] boolValue]);
    }
}

- (void)chooseContainer:(NSString *)value
{
    [self JS:[NSString stringWithFormat:@"(function(){var s=document.querySelector('#macdown-preview-format select[data-mp-scope=container]');s.value='%@';s.dispatchEvent(new Event('change',{bubbles:true}));})()",value]];
}

- (void)testHeadingAndContainerAreIndependentAndMixedBlocksKeepOnlyTheirCommonContainer
{
    [self loadSource:@"::: {.callout-note}\n## Title\n# **Heading**\n\nBody\n:::\n\nNeighbor.\n"];
    [self selectFromText:@"Heading" throughText:@"Heading"];
    XCTAssertEqualObjects([self JS:@"String(document.querySelectorAll('#macdown-preview-format select').length)"],@"2");
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
    XCTAssertTrue([[self JS:@"Array.from(document.querySelectorAll('#macdown-preview-format button')).every(function(b){return b.disabled;})"] boolValue]);
    XCTAssertTrue([[self JS:@"Array.from(document.querySelectorAll('#macdown-preview-format select')).every(function(s){return !s.disabled;})"] boolValue]);
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
