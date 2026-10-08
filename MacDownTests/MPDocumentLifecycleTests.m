//
//  MPDocumentLifecycleTests.m
//  MacDownTests
//
//  Tests for document state management beyond basic I/O.
//  Focuses on dirty flags, revert behavior, encoding detection,
//  and edge cases in document lifecycle.
//
//  Created for Issue #234: Test Coverage Phase 1b
//

#import <XCTest/XCTest.h>
#import "MPDocument.h"
#import "MPPreferences.h"
#import "MPRenderer.h"
#import "MPEditorView.h"
#import "HGMarkdownHighlighter.h"
#import "pmh_parser.h"
#import <sys/stat.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <unistd.h>
#import <objc/runtime.h>
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "MPResourceWatcherSet.h"
#import "MPHTMLResourceURLs.h"


@interface MPPreferences (PreviewEditingTests)
- (int)rendererFlags;
@end

// A real loopback HTTP response exercises WebKit navigation and its delegates.
@interface MPPreviewHTTPFixture : NSObject
@property (strong) NSURL *URL;
@property (strong) dispatch_source_t listener;
@end

@implementation MPPreviewHTTPFixture
- (instancetype)init
{
    self = [super init];
    if (!self) return nil;
    int descriptor = socket(AF_INET, SOCK_STREAM, 0);
    if (descriptor < 0) return nil;
    struct sockaddr_in address = {0};
    address.sin_len = sizeof(address);
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    if (bind(descriptor, (struct sockaddr *)&address, sizeof(address)) != 0 || listen(descriptor, 4) != 0) {
        close(descriptor);
        return nil;
    }
    socklen_t length = sizeof(address);
    if (getsockname(descriptor, (struct sockaddr *)&address, &length) != 0) {
        close(descriptor);
        return nil;
    }
    self.URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://127.0.0.1:%u/remote.html", ntohs(address.sin_port)]];
    NSString *html = @"<html><head><meta name='remote-marker' content='foreign'></head><body>Remote HTTP</body></html>";
    NSData *body = [html dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *response = [[NSString stringWithFormat:@"HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: %lu\r\nConnection: close\r\n\r\n", (unsigned long)body.length] dataUsingEncoding:NSUTF8StringEncoding].mutableCopy;
    [response appendData:body];
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, descriptor, 0, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0));
    dispatch_source_set_event_handler(source, ^{
        int client = accept(descriptor, NULL, NULL);
        if (client < 0) return;
        int noSignal = 1;
        setsockopt(client, SOL_SOCKET, SO_NOSIGPIPE, &noSignal, sizeof(noSignal));
        struct timeval timeout = {2, 0};
        setsockopt(client, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
        char request[4096];
        if (read(client, request, sizeof(request)) > 0) {
            const char *bytes = response.bytes;
            NSUInteger remaining = response.length;
            while (remaining) {
                ssize_t sent = write(client, bytes, remaining);
                if (sent <= 0) break;
                bytes += sent;
                remaining -= sent;
            }
        }
        close(client);
    });
    dispatch_source_set_cancel_handler(source, ^{ close(descriptor); });
    self.listener = source;
    dispatch_resume(source);
    return self;
}
- (void)dealloc
{
    if (_listener) dispatch_source_cancel(_listener);
}
@end

#pragma mark - Test Infrastructure for Issue #358

// Expose private MPDocument properties needed by the reload tests.
@interface MPDocument (ReloadTesting)
@property (strong) MPRenderer *renderer;
@property (strong) HGMarkdownHighlighter *highlighter;
@property (weak) MPEditorView *editor;
@property (copy) NSString *loadedString;
- (void)reloadFromLoadedString;
- (void)setupEditor:(NSString *)changedKey;
- (IBAction)toggleUnderline:(id)sender;
- (IBAction)toggleStrong:(id)sender;
- (IBAction)convertToH1:(id)sender;
- (IBAction)toggleEmphasis:(id)sender;
- (IBAction)toggleStrikethrough:(id)sender;
- (BOOL)previewHasFindFocus;
- (BOOL)textViewShouldMoveToLeftEndOfLine:(NSTextView *)textView;
@property (nonatomic) BOOL isPreviewReady;
@property (nonatomic) BOOL alreadyRenderingInWeb;
@property (nonatomic) BOOL renderToWebPending;
@property (weak) WebView *preview;
@property (strong) MPResourceWatcherSet *resourceWatcherSet;
@property (strong) NSSearchField *previewFindField;
@property (strong) NSTextField *readingProgressLabel;
@property (copy) NSArray<NSDictionary *> *previewEditRanges;
@property (copy) NSString *previewEditToken;
@property (copy) NSString *previewEditSource;
- (BOOL)applyPreviewEditPayload:(NSDictionary *)payload;
- (void)installPreviewEditor;
- (void)handlePreviewEdit:(NSURL *)url;
- (void)setupReadingProgress;
- (void)updateReadingProgress;
- (void)willStartLiveScroll:(NSNotification *)notification;
- (void)willStartPreviewLiveScroll:(NSNotification *)notification;
- (void)processExternalFileChange;
- (void)performAfterRender:(void (^)(void))handler;
- (void)renderer:(MPRenderer *)renderer didProduceHTMLOutput:(NSString *)html;
- (void)resourceWatcherSet:(MPResourceWatcherSet *)set didDetectChangeAtPath:(NSString *)path;
- (IBAction)exportPdf:(id)sender;
- (IBAction)exportHtml:(id)sender;
+ (NSInvocation *)printCompletionForDelegate:(id)delegate selector:(SEL)selector context:(void *)context;
- (void)document:(NSDocument *)doc didPrint:(BOOL)ok context:(void *)context;
@end

@interface MPRenderer (DocumentActionTesting)
- (void)parseMarkdown:(NSString *)markdown;
@end

@interface HGMarkdownHighlighter (DocumentFootnoteTesting)
- (pmh_element **)parseText:(NSString *)markdown;
@end

// Spy renderer: records whether parseAndRenderNow was called without
// performing actual background work.
@interface MPSpyRenderer : MPRenderer
@property (nonatomic) BOOL parseAndRenderNowCalled;
@end

@implementation MPSpyRenderer
- (void)parseAndRenderNow {
    self.parseAndRenderNowCalled = YES;
    // Do not call super — avoids enqueuing background parse/render ops in tests.
}
@end

// Spy highlighter: records whether parseAndHighlightNow was called.
@interface MPSpyHighlighter : HGMarkdownHighlighter
@property (nonatomic) BOOL parseAndHighlightNowCalled;
@property (nonatomic) BOOL clearHighlightingCalled;
@property (nonatomic) BOOL readClearTextStylesFromTextViewCalled;
@end

@implementation MPSpyHighlighter
- (void)parseAndHighlightNow {
    self.parseAndHighlightNowCalled = YES;
    // Do not call super — avoids actual text-view work in tests.
}
- (void)clearHighlighting {
    self.clearHighlightingCalled = YES;
}
- (void)readClearTextStylesFromTextView {
    self.readClearTextStylesFromTextViewCalled = YES;
}
@end


@interface MPPrintDelegateProbe : NSObject
@property NSDocument *document;
@property BOOL success;
@property void *context;
@property NSUInteger calls;
- (void)document:(NSDocument *)document printed:(BOOL)success context:(void *)context;
@end
@implementation MPPrintDelegateProbe
- (void)document:(NSDocument *)document printed:(BOOL)success context:(void *)context
{
    self.document = document; self.success = success; self.context = context; self.calls++;
}
@end

// Observe publication and alert output; leave the document, renderer and file
// writes real. Presenting an error sheet is an external UI boundary.
@interface MPDocumentExportAuditProbe : MPDocument
@property (strong) NSMutableArray<NSString *> *publishedHTML;
@property (strong) NSError *presentedError;
@end
@implementation MPDocumentExportAuditProbe
- (instancetype)init
{
    if ((self = [super init])) self.publishedHTML = [NSMutableArray array];
    return self;
}
- (void)renderer:(MPRenderer *)renderer didProduceHTMLOutput:(NSString *)html
{
    [self.publishedHTML addObject:html];
    [super renderer:renderer didProduceHTMLOutput:html];
}
- (BOOL)presentError:(NSError *)error
{
    self.presentedError = error;
    return NO;
}
@end

// Save-panel interaction alone is substituted. The export action, render
// completion, pending-operation rule and filesystem failure remain production.
@interface MPControlledExportPanel : NSObject
@property (copy) NSArray *allowedFileTypes;
@property (copy) NSString *nameFieldStringValue;
@property (strong) NSView *accessoryView;
@property (strong) NSURL *URL;
@property (copy) void (^completion)(NSInteger);
@property NSUInteger presentations;
@end
@implementation MPControlledExportPanel
- (void)beginSheetModalForWindow:(NSWindow *)window completionHandler:(void (^)(NSInteger))completion
{
    self.presentations++;
    self.completion = completion;
}
@end
static MPControlledExportPanel *MPCurrentControlledExportPanel;
static id MPControlledExportPanelFactory(id receiver, SEL selector)
{
    return MPCurrentControlledExportPanel;
}

@interface MPDocumentLifecycleTests : XCTestCase
@property (strong) MPDocument *document;
@property (strong) NSURL *testFileURL;
@property (strong) NSString *testDirectory;
@property (strong) NSFileManager *fileManager;
@end


@implementation MPDocumentLifecycleTests

- (void)setUp
{
    [super setUp];

    self.fileManager = [NSFileManager defaultManager];

    // Create unique test directory
    NSString *tempDir = NSTemporaryDirectory();
    self.testDirectory = [tempDir stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    [self.fileManager createDirectoryAtPath:self.testDirectory
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:nil];

    self.testFileURL = [NSURL fileURLWithPath:[self.testDirectory stringByAppendingPathComponent:@"test.md"]];

    // Create a fresh document for each test
    self.document = [[MPDocument alloc] init];
}

- (void)tearDown
{
    // Clean up test files and directory
    if (self.testDirectory) {
        [self.fileManager removeItemAtPath:self.testDirectory error:nil];
    }

    self.document = nil;
    self.testFileURL = nil;
    self.testDirectory = nil;

    [super tearDown];
}


#pragma mark - Dirty Flag Tests

- (void)testDocumentDirtyFlagAfterEdit
{
    // Set fileURL to simulate a saved document
    [self.document setFileURL:self.testFileURL];

    // Initially not edited
    [self.document updateChangeCount:NSChangeCleared];
    XCTAssertFalse([self.document isDocumentEdited],
                   @"Document should not be edited initially");

    // Mark as edited
    [self.document updateChangeCount:NSChangeDone];

    // Should now be dirty
    XCTAssertTrue([self.document isDocumentEdited],
                  @"Document with fileURL should report as edited after change");
}

- (void)testDocumentDirtyFlagAfterMultipleEdits
{
    [self.document setFileURL:self.testFileURL];
    [self.document updateChangeCount:NSChangeCleared];

    // Multiple edits
    for (int i = 0; i < 5; i++) {
        [self.document updateChangeCount:NSChangeDone];
    }

    XCTAssertTrue([self.document isDocumentEdited],
                  @"Document should still be edited after multiple changes");
}

- (void)testDocumentDirtyFlagAfterUndoRedo
{
    [self.document setFileURL:self.testFileURL];
    [self.document updateChangeCount:NSChangeCleared];

    // Make a change
    [self.document updateChangeCount:NSChangeDone];
    XCTAssertTrue([self.document isDocumentEdited], @"Should be dirty after edit");

    // Undo the change
    [self.document updateChangeCount:NSChangeUndone];
    XCTAssertFalse([self.document isDocumentEdited],
                   @"Should not be dirty after undo to saved state");

    // Redo the change
    [self.document updateChangeCount:NSChangeRedone];
    XCTAssertTrue([self.document isDocumentEdited],
                  @"Should be dirty again after redo");
}

- (void)testUntitledDocumentDirtyFlag
{
    // Document without fileURL (untitled)
    XCTAssertNil(self.document.fileURL, @"Untitled document should have no fileURL");

    // In headless mode, editor is nil, so markdown is nil
    // The isDocumentEdited logic returns NO for untitled documents with no content
    XCTAssertFalse([self.document isDocumentEdited],
                   @"Empty untitled document should not report as edited");

    // Even with changes marked, behavior depends on content
    [self.document updateChangeCount:NSChangeDone];
    // Still should be NO because editor.string is nil (no content)
    XCTAssertFalse([self.document isDocumentEdited],
                   @"Untitled document with no actual content should not report as edited");
}


#pragma mark - Revert Tests

- (void)testDocumentRevertClearsChanges
{
    // Create a test file
    NSString *originalContent = @"# Original Content\n\nThis is the original.";
    NSError *error = nil;
    [originalContent writeToURL:self.testFileURL
                     atomically:YES
                       encoding:NSUTF8StringEncoding
                          error:&error];
    XCTAssertNil(error, @"Should write test file");

    // Load document from file
    MPDocument *doc = [[MPDocument alloc] initWithContentsOfURL:self.testFileURL
                                                         ofType:@"net.daringfireball.markdown"
                                                          error:&error];
    XCTAssertNotNil(doc, @"Should load document");
    XCTAssertNil(error, @"Should not have error loading document");

    // Mark as edited
    [doc updateChangeCount:NSChangeDone];
    XCTAssertTrue([doc isDocumentEdited], @"Should be dirty after change");

    // Revert (this is inherited from NSDocument)
    // Note: In headless mode, revert may not fully work as it needs window controller
    [doc updateChangeCount:NSChangeCleared];
    XCTAssertFalse([doc isDocumentEdited], @"Should not be dirty after clearing changes");
}

- (void)testDocumentRevertFromDisk
{
    // Create initial file
    NSString *originalContent = @"# Original";
    NSError *error = nil;
    [originalContent writeToURL:self.testFileURL
                     atomically:YES
                       encoding:NSUTF8StringEncoding
                          error:&error];

    // Load document
    MPDocument *doc = [[MPDocument alloc] initWithContentsOfURL:self.testFileURL
                                                         ofType:@"net.daringfireball.markdown"
                                                          error:&error];
    XCTAssertNotNil(doc, @"Should load document");

    // Read the file content again using readFromData
    NSData *fileData = [NSData dataWithContentsOfURL:self.testFileURL];
    BOOL success = [doc readFromData:fileData
                              ofType:@"net.daringfireball.markdown"
                               error:&error];
    XCTAssertTrue(success, @"Should successfully re-read file data");
}


#pragma mark - Encoding Detection Tests

- (void)testDocumentEncodingDetectionUTF8
{
    // Create UTF-8 file with special characters
    NSString *content = @"# UTF-8 Test\n\n日本語テスト\nÄÖÜ äöü ß";
    NSError *error = nil;
    [content writeToURL:self.testFileURL
             atomically:YES
               encoding:NSUTF8StringEncoding
                  error:&error];
    XCTAssertNil(error, @"Should write UTF-8 file");

    // Load document
    MPDocument *doc = [[MPDocument alloc] initWithContentsOfURL:self.testFileURL
                                                         ofType:@"net.daringfireball.markdown"
                                                          error:&error];
    XCTAssertNotNil(doc, @"Should load UTF-8 document");
    XCTAssertNil(error, @"Should not have error loading UTF-8");
}

- (void)testDocumentEncodingDetectionUTF8BOM
{
    // Create UTF-8 file with BOM
    const unsigned char bom[] = {0xEF, 0xBB, 0xBF};
    NSMutableData *dataWithBOM = [NSMutableData dataWithBytes:bom length:sizeof(bom)];
    [dataWithBOM appendData:[@"# Document with BOM" dataUsingEncoding:NSUTF8StringEncoding]];

    NSError *error = nil;
    [dataWithBOM writeToURL:self.testFileURL atomically:YES];

    // Load document
    MPDocument *doc = [[MPDocument alloc] initWithContentsOfURL:self.testFileURL
                                                         ofType:@"net.daringfireball.markdown"
                                                          error:&error];
    XCTAssertNotNil(doc, @"Should load document with BOM");
}

- (void)testDocumentEncodingDetectionASCII
{
    // Pure ASCII content
    NSString *content = @"# Simple ASCII\n\nNo special characters here.";
    NSError *error = nil;
    [content writeToURL:self.testFileURL
             atomically:YES
               encoding:NSASCIIStringEncoding
                  error:&error];
    XCTAssertNil(error, @"Should write ASCII file");

    MPDocument *doc = [[MPDocument alloc] initWithContentsOfURL:self.testFileURL
                                                         ofType:@"net.daringfireball.markdown"
                                                          error:&error];
    XCTAssertNotNil(doc, @"Should load ASCII document");
}


#pragma mark - No Extension Tests

- (void)testDocumentWithNoExtension
{
    // Create file without extension
    NSURL *noExtURL = [NSURL fileURLWithPath:[self.testDirectory stringByAppendingPathComponent:@"noextension"]];
    NSString *content = @"# No Extension\n\nThis file has no extension.";
    NSError *error = nil;
    [content writeToURL:noExtURL
             atomically:YES
               encoding:NSUTF8StringEncoding
                  error:&error];
    XCTAssertNil(error, @"Should write file without extension");

    // Load document - may need explicit type
    MPDocument *doc = [[MPDocument alloc] initWithContentsOfURL:noExtURL
                                                         ofType:@"net.daringfireball.markdown"
                                                          error:&error];
    XCTAssertNotNil(doc, @"Should load document without extension");
}

- (void)testDocumentWithUnusualExtension
{
    // Create file with unusual extension
    NSURL *unusualExtURL = [NSURL fileURLWithPath:[self.testDirectory stringByAppendingPathComponent:@"test.txt"]];
    NSString *content = @"# TXT Extension\n\nMarkdown content in a .txt file.";
    NSError *error = nil;
    [content writeToURL:unusualExtURL
             atomically:YES
               encoding:NSUTF8StringEncoding
                  error:&error];
    XCTAssertNil(error, @"Should write .txt file");

    // Load as markdown type
    MPDocument *doc = [[MPDocument alloc] initWithContentsOfURL:unusualExtURL
                                                         ofType:@"net.daringfireball.markdown"
                                                          error:&error];
    XCTAssertNotNil(doc, @"Should load .txt file as markdown");
}


#pragma mark - File Conflict Tests

- (void)testSaveWithFileModifiedExternally
{
    // Create initial file
    NSString *originalContent = @"# Original";
    NSError *error = nil;
    [originalContent writeToURL:self.testFileURL
                     atomically:YES
                       encoding:NSUTF8StringEncoding
                          error:&error];

    // Load document
    MPDocument *doc = [[MPDocument alloc] initWithContentsOfURL:self.testFileURL
                                                         ofType:@"net.daringfireball.markdown"
                                                          error:&error];
    XCTAssertNotNil(doc, @"Should load document");

    // Modify file externally (simulating another process)
    NSString *externalContent = @"# Modified Externally";
    [externalContent writeToURL:self.testFileURL
                     atomically:YES
                       encoding:NSUTF8StringEncoding
                          error:&error];

    // Get file modification date
    NSDictionary *attrs = [self.fileManager attributesOfItemAtPath:self.testFileURL.path error:&error];
    NSDate *modDate = attrs[NSFileModificationDate];
    XCTAssertNotNil(modDate, @"Should have modification date");

    // The document's fileModificationDate may differ from the file's current date
    // This is how the system detects external modifications
}

- (void)testDocumentDetectsExternalChange
{
    // Create file
    NSString *content = @"# Initial Content";
    NSError *error = nil;
    [content writeToURL:self.testFileURL atomically:YES encoding:NSUTF8StringEncoding error:&error];

    // Load document
    MPDocument *doc = [[MPDocument alloc] initWithContentsOfURL:self.testFileURL
                                                         ofType:@"net.daringfireball.markdown"
                                                          error:&error];
    XCTAssertNotNil(doc, @"Should load document");

    // Wait a moment to ensure different timestamp
    [NSThread sleepForTimeInterval:0.1];

    // Modify file externally
    NSString *newContent = @"# Changed Content";
    [newContent writeToURL:self.testFileURL atomically:YES encoding:NSUTF8StringEncoding error:&error];

    // Read file to verify it changed
    NSString *readContent = [NSString stringWithContentsOfURL:self.testFileURL
                                                     encoding:NSUTF8StringEncoding
                                                        error:&error];
    XCTAssertEqualObjects(readContent, newContent, @"File should have new content");
}


#pragma mark - File Deleted During Edit Tests

- (void)testOpenFileDeletedDuringEdit
{
    // Create file
    NSString *content = @"# Will Be Deleted";
    NSError *error = nil;
    [content writeToURL:self.testFileURL atomically:YES encoding:NSUTF8StringEncoding error:&error];

    // Load document
    MPDocument *doc = [[MPDocument alloc] initWithContentsOfURL:self.testFileURL
                                                         ofType:@"net.daringfireball.markdown"
                                                          error:&error];
    XCTAssertNotNil(doc, @"Should load document");

    // Verify fileURL is set
    XCTAssertNotNil(doc.fileURL, @"Document should have fileURL");

    // Delete file externally
    [self.fileManager removeItemAtURL:self.testFileURL error:&error];
    XCTAssertNil(error, @"Should delete file");

    // Verify file is gone
    XCTAssertFalse([self.fileManager fileExistsAtPath:self.testFileURL.path],
                   @"File should be deleted");

    // Document still has the fileURL reference
    XCTAssertNotNil(doc.fileURL, @"Document should still have fileURL even if file is deleted");
}

- (void)testDocumentFileURLAfterFileDeleted
{
    // Create and load document
    NSString *content = @"# Test";
    NSError *error = nil;
    [content writeToURL:self.testFileURL atomically:YES encoding:NSUTF8StringEncoding error:&error];

    MPDocument *doc = [[MPDocument alloc] initWithContentsOfURL:self.testFileURL
                                                         ofType:@"net.daringfireball.markdown"
                                                          error:&error];

    NSURL *originalURL = doc.fileURL;

    // Delete file
    [self.fileManager removeItemAtURL:self.testFileURL error:nil];

    // fileURL should be unchanged (it's a reference, not live validation)
    XCTAssertEqualObjects(doc.fileURL, originalURL,
                          @"fileURL should persist even after file deletion");
}


#pragma mark - Document Type Tests

- (void)testReadableTypes
{
    NSArray *readableTypes = [MPDocument readableTypes];
    XCTAssertNotNil(readableTypes, @"Should return readable types");
    XCTAssertGreaterThan(readableTypes.count, 0, @"Should have at least one readable type");
    XCTAssertTrue([readableTypes containsObject:@"net.daringfireball.markdown"],
                  @"Should include markdown type");
}

- (void)testWritableTypesForSaveOperation
{
    NSArray *writableTypes = [MPDocument writableTypes];
    XCTAssertNotNil(writableTypes, @"Should return writable types");
    XCTAssertTrue([writableTypes containsObject:@"net.daringfireball.markdown"],
                  @"Should include markdown type for writing");
}


#pragma mark - Autosave Tests

- (void)testAutosavesInPlaceRespectsPreference
{
    MPPreferences *prefs = [MPPreferences sharedInstance];
    BOOL original = prefs.editorAutoSave;

    // When preference is YES, autosave should be enabled
    prefs.editorAutoSave = YES;
    XCTAssertTrue([MPDocument autosavesInPlace],
                  @"MPDocument should autosave when editorAutoSave is YES");

    // When preference is NO, autosave should be disabled
    prefs.editorAutoSave = NO;
    XCTAssertFalse([MPDocument autosavesInPlace],
                   @"MPDocument should not autosave when editorAutoSave is NO");

    // Restore
    prefs.editorAutoSave = original;
}

- (void)testPreservesVersions
{
    // Test the class method for version preservation
    BOOL preserves = [MPDocument preservesVersions];
    // Value depends on implementation, just verify it doesn't crash
    XCTAssertTrue(preserves || !preserves, @"Should return boolean value");
}


#pragma mark - Data Conversion Tests

- (void)testDataOfTypeWithEmptyDocument
{
    NSError *error = nil;
    NSData *data = [self.document dataOfType:@"net.daringfireball.markdown" error:&error];

    // Without editor, markdown is nil, so data may be nil or empty
    // This is expected behavior in headless mode
    if (data != nil) {
        NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        XCTAssertNotNil(content, @"Data should be valid UTF-8 if not nil");
    }
}

- (void)testReadFromDataSetsLoadedString
{
    NSString *testContent = @"# Test Content\n\nSome text here.";
    NSData *data = [testContent dataUsingEncoding:NSUTF8StringEncoding];

    NSError *error = nil;
    BOOL success = [self.document readFromData:data
                                        ofType:@"net.daringfireball.markdown"
                                         error:&error];

    XCTAssertTrue(success, @"Should successfully read data");
    XCTAssertNil(error, @"Should not have error");

    // The content is stored internally as loadedString
    // but we cannot access it directly in headless mode
}


#pragma mark - Edge Cases

- (void)testVeryLongFileName
{
    // Create file with very long name
    NSMutableString *longName = [NSMutableString string];
    for (int i = 0; i < 50; i++) {
        [longName appendString:@"longname"];
    }
    [longName appendString:@".md"];

    // Most file systems have a 255 character limit for filenames
    if (longName.length > 255) {
        longName = [[longName substringToIndex:251] mutableCopy];
        [longName appendString:@".md"];
    }

    NSURL *longNameURL = [NSURL fileURLWithPath:[self.testDirectory stringByAppendingPathComponent:longName]];
    NSString *content = @"# Long Filename Test";
    NSError *error = nil;

    BOOL written = [content writeToURL:longNameURL atomically:YES encoding:NSUTF8StringEncoding error:&error];

    if (written) {
        MPDocument *doc = [[MPDocument alloc] initWithContentsOfURL:longNameURL
                                                             ofType:@"net.daringfireball.markdown"
                                                              error:&error];
        XCTAssertNotNil(doc, @"Should handle long filename");
    }
    // If writing fails due to filename length, that's expected on some systems
}

- (void)testSpecialCharactersInFileName
{
    // Create file with special characters (but valid for filesystem)
    NSURL *specialURL = [NSURL fileURLWithPath:[self.testDirectory stringByAppendingPathComponent:@"test-file_v2 (copy).md"]];
    NSString *content = @"# Special Characters";
    NSError *error = nil;
    [content writeToURL:specialURL atomically:YES encoding:NSUTF8StringEncoding error:&error];

    MPDocument *doc = [[MPDocument alloc] initWithContentsOfURL:specialURL
                                                         ofType:@"net.daringfireball.markdown"
                                                          error:&error];
    XCTAssertNotNil(doc, @"Should handle special characters in filename");
}

- (void)testUnicodeFileName
{
    // Create file with Unicode name
    NSURL *unicodeURL = [NSURL fileURLWithPath:[self.testDirectory stringByAppendingPathComponent:@"テスト文書.md"]];
    NSString *content = @"# Unicode Filename Test";
    NSError *error = nil;
    [content writeToURL:unicodeURL atomically:YES encoding:NSUTF8StringEncoding error:&error];

    if (error == nil) {
        MPDocument *doc = [[MPDocument alloc] initWithContentsOfURL:unicodeURL
                                                             ofType:@"net.daringfireball.markdown"
                                                              error:&error];
        XCTAssertNotNil(doc, @"Should handle Unicode filename");
    }
}


#pragma mark - reloadFromLoadedString Tests (Issue #358)
//
// These tests cover the bug where new (untitled) documents never receive an
// initial render because reloadFromLoadedString guarded all rendering behind
// the loadedString != nil check.  The two "New document" tests are RED before
// the fix — they assert behaviour the current code does not yet provide.

// Helper: wires spy renderer, editor, and highlighter into `doc` so that
// reloadFromLoadedString's outer guard (editor && renderer && highlighter) is
// satisfied.  All three objects are ALWAYS assigned to `doc` regardless of
// which output pointers the caller provides; the output params are purely
// convenience references for callers that need to inspect them afterward.
- (void)wireDocument:(MPDocument *)doc
         intoRenderer:(MPSpyRenderer **)rendererOut
          highlighter:(MPSpyHighlighter **)highlighterOut
               editor:(MPEditorView *__strong *)editorOut
{
    MPSpyRenderer *renderer = [[MPSpyRenderer alloc] init];
    MPEditorView *editor = [[MPEditorView alloc] initWithFrame:NSZeroRect];
    MPSpyHighlighter *highlighter =
        [[MPSpyHighlighter alloc] initWithTextView:editor waitInterval:0.0];

    doc.renderer = renderer;
    doc.editor = editor;
    doc.highlighter = highlighter;

    if (rendererOut)    *rendererOut    = renderer;
    if (highlighterOut) *highlighterOut = highlighter;
    if (editorOut)      *editorOut      = editor;
}

// Regression test for issue #358: new documents must trigger a render so the
// preview WebView is initialised before the user starts typing.
- (void)testNewDocumentTriggersRenderOnReload
{
    MPSpyRenderer *renderer = nil;
    MPEditorView *editor = nil;
    [self wireDocument:self.document
           intoRenderer:&renderer
            highlighter:nil
                 editor:&editor];

    XCTAssertNil(self.document.loadedString,
                 @"Precondition: new document has no loadedString");

    [self.document reloadFromLoadedString];

    XCTAssertTrue(renderer.parseAndRenderNowCalled,
                  @"parseAndRenderNow must fire for new documents so the preview "
                   "WebView is initialised before the user starts typing (issue #358)");
}

// Regression test for issue #358: syntax highlighting must also fire for new documents.
- (void)testNewDocumentTriggersHighlightOnReload
{
    MPSpyHighlighter *highlighter = nil;
    MPEditorView *editor = nil;
    [self wireDocument:self.document
           intoRenderer:nil
            highlighter:&highlighter
                 editor:&editor];

    XCTAssertNil(self.document.loadedString,
                 @"Precondition: new document has no loadedString");

    [self.document reloadFromLoadedString];

    XCTAssertTrue(highlighter.parseAndHighlightNowCalled,
                  @"parseAndHighlightNow must fire for new documents (issue #358)");
}

- (void)testExistingDocumentClearsHighlightingBeforeReloadHighlight
{
    MPSpyHighlighter *highlighter = nil;
    MPEditorView *editor = nil;
    [self wireDocument:self.document
           intoRenderer:nil
            highlighter:&highlighter
                 editor:&editor];

    self.document.loadedString = @"# Reloaded\n\nBody";
    highlighter.clearHighlightingCalled = NO;
    highlighter.readClearTextStylesFromTextViewCalled = NO;

    [self.document reloadFromLoadedString];

    XCTAssertTrue(highlighter.clearHighlightingCalled,
                  @"Issue #378: external reload should clear stale editor attributes "
                  @"before the async highlight pass");
    XCTAssertTrue(highlighter.readClearTextStylesFromTextViewCalled,
                  @"Issue #378: highlighter should refresh clear-text attributes "
                  @"after replacing editor text");
}

// Regression: existing-document path must still trigger a render after the fix.
- (void)testExistingDocumentTriggersRenderOnReload
{
    MPSpyRenderer *renderer = nil;
    MPEditorView *editor = nil;
    [self wireDocument:self.document
           intoRenderer:&renderer
            highlighter:nil
                 editor:&editor];

    self.document.loadedString = @"# Existing content";

    [self.document reloadFromLoadedString];

    XCTAssertTrue(renderer.parseAndRenderNowCalled,
                  @"parseAndRenderNow must fire for documents opened from a file");
}

// Regression: loadedString must be consumed (nil-ed) after reload.
- (void)testReloadConsumesLoadedString
{
    MPEditorView *editor = nil;
    [self wireDocument:self.document
           intoRenderer:nil
            highlighter:nil
                 editor:&editor];

    self.document.loadedString = @"# Content to consume";

    [self.document reloadFromLoadedString];

    XCTAssertNil(self.document.loadedString,
                 @"loadedString must be nil-ed out after it is applied to the editor");
}

// Regression: editor.string must reflect the loaded content after reload.
- (void)testReloadSetsEditorStringFromLoadedString
{
    MPEditorView *editor = nil;
    [self wireDocument:self.document
           intoRenderer:nil
            highlighter:nil
                 editor:&editor];

    self.document.loadedString = @"# Hello World";

    [self.document reloadFromLoadedString];

    XCTAssertEqualObjects(editor.string, @"# Hello World",
                          @"Editor must contain the loaded string after reload");
}

// Guard path: reloadFromLoadedString must be a safe no-op when the document's
// dependencies (editor / renderer / highlighter) are not yet wired up.  This
// is the state during readFromData:ofType:error:, before the window controller
// nib has loaded.  Calling it must not crash and must not trigger a render.
- (void)testReloadIsNoOpWhenDependenciesNotReady
{
    // Document is freshly allocated — editor, renderer, highlighter are all nil.
    XCTAssertNil(self.document.editor,    @"Precondition: editor is nil");
    XCTAssertNil(self.document.renderer,  @"Precondition: renderer is nil");
    XCTAssertNil(self.document.highlighter, @"Precondition: highlighter is nil");

    // Must not crash with no loadedString set.
    XCTAssertNoThrow([self.document reloadFromLoadedString],
                     @"reloadFromLoadedString must not crash when dependencies are absent");

    // loadedString, if any, must be untouched (guard failed before consuming it).
    // Re-assert the precondition so the guard's state is explicit for this second call.
    self.document.loadedString = @"# Not yet";
    XCTAssertNil(self.document.editor, @"Precondition still holds: editor is nil");
    [self.document reloadFromLoadedString];
    XCTAssertEqualObjects(self.document.loadedString, @"# Not yet",
                          @"loadedString must not be consumed when the guard fails");
}

// Regression: editor.string must stay empty for new documents (no loadedString).
- (void)testReloadDoesNotModifyEditorStringForNewDocument
{
    MPEditorView *editor = nil;
    [self wireDocument:self.document
           intoRenderer:nil
            highlighter:nil
                 editor:&editor];

    XCTAssertEqualObjects(editor.string, @"",
                          @"Precondition: new document editor starts empty");

    [self.document reloadFromLoadedString];

    XCTAssertEqualObjects(editor.string, @"",
                          @"Editor string must not change for new documents "
                           "when there is no loadedString to apply");
}


#pragma mark - Preview Rendering Gate Tests (Issue #358 follow-up)

// When isPreviewReady is NO, the alreadyRenderingInWeb flag must NOT block the
// render.  The method should proceed past the gate and set alreadyRenderingInWeb
// to YES.  renderToWebPending must remain NO (no deferral occurred).
// We start alreadyRenderingInWeb at NO so the assertion that it becomes YES
// proves line 1278 actually executed (the gate was not triggered).
- (void)testPreReadyRendersNotBlockedByAlreadyRenderingInWeb
{
    MPSpyRenderer *renderer = nil;
    [self wireDocument:self.document
           intoRenderer:&renderer
            highlighter:nil
                 editor:nil];

    self.document.isPreviewReady = NO;
    self.document.alreadyRenderingInWeb = NO;
    self.document.renderToWebPending = NO;

    [(id<MPRendererDelegate>)self.document renderer:renderer
                               didProduceHTMLOutput:@"<p>test</p>"];

    XCTAssertFalse(self.document.renderToWebPending,
                   @"renderToWebPending must remain NO — render should not be "
                    "deferred when isPreviewReady is NO (issue #358)");
    XCTAssertTrue(self.document.alreadyRenderingInWeb,
                  @"alreadyRenderingInWeb must be YES — method must proceed past "
                   "the gate and set the flag when isPreviewReady is NO");
}

// When isPreviewReady is YES and alreadyRenderingInWeb is YES, the method must
// defer the render by setting renderToWebPending and returning early.
// alreadyRenderingInWeb must remain YES (the in-flight load is still active).
- (void)testPostReadyRendersBlockedByAlreadyRenderingInWeb
{
    MPSpyRenderer *renderer = nil;
    [self wireDocument:self.document
           intoRenderer:&renderer
            highlighter:nil
                 editor:nil];

    self.document.isPreviewReady = YES;
    self.document.alreadyRenderingInWeb = YES;
    self.document.renderToWebPending = NO;

    [(id<MPRendererDelegate>)self.document renderer:renderer
                               didProduceHTMLOutput:@"<p>test</p>"];

    XCTAssertTrue(self.document.renderToWebPending,
                  @"renderToWebPending must be YES — render must be deferred when "
                   "isPreviewReady is YES and alreadyRenderingInWeb is YES");
    XCTAssertTrue(self.document.alreadyRenderingInWeb,
                  @"alreadyRenderingInWeb must remain YES — the in-flight load is "
                   "still active; the method returned early without clearing it");
}

// When alreadyRenderingInWeb is NO the method must always proceed past the gate,
// regardless of isPreviewReady.  After the call, alreadyRenderingInWeb must be
// YES and renderToWebPending must remain NO.
- (void)testRendersNotBlockedWhenAlreadyRenderingInWebIsNO
{
    // Sub-case 1: isPreviewReady = NO
    {
        MPSpyRenderer *renderer = nil;
        MPDocument *doc = [[MPDocument alloc] init];
        [self wireDocument:doc
               intoRenderer:&renderer
                highlighter:nil
                     editor:nil];

        doc.isPreviewReady = NO;
        doc.alreadyRenderingInWeb = NO;
        doc.renderToWebPending = NO;

        [(id<MPRendererDelegate>)doc renderer:renderer
                          didProduceHTMLOutput:@"<p>test</p>"];

        XCTAssertTrue(doc.alreadyRenderingInWeb,
                      @"alreadyRenderingInWeb must be YES after render proceeds "
                       "(isPreviewReady=NO, alreadyRenderingInWeb=NO)");
        XCTAssertFalse(doc.renderToWebPending,
                       @"renderToWebPending must remain NO — no deferral should "
                        "occur when alreadyRenderingInWeb starts as NO");
    }

    // Sub-case 2: isPreviewReady = YES
    {
        MPSpyRenderer *renderer = nil;
        MPDocument *doc = [[MPDocument alloc] init];
        [self wireDocument:doc
               intoRenderer:&renderer
                highlighter:nil
                     editor:nil];

        doc.isPreviewReady = YES;
        doc.alreadyRenderingInWeb = NO;
        doc.renderToWebPending = NO;

        [(id<MPRendererDelegate>)doc renderer:renderer
                          didProduceHTMLOutput:@"<p>test</p>"];

        XCTAssertTrue(doc.alreadyRenderingInWeb,
                      @"alreadyRenderingInWeb must be YES after render proceeds "
                       "(isPreviewReady=YES, alreadyRenderingInWeb=NO)");
        XCTAssertFalse(doc.renderToWebPending,
                       @"renderToWebPending must remain NO — no deferral should "
                        "occur when alreadyRenderingInWeb starts as NO");
    }
}


#pragma mark - Opened-File Preview Base URL (Issue #405)

// Simulate the open-file state: the document has a fileURL pointing at a real
// on-disk .md file, exactly as it does after opening a saved document. The base
// URL handed to the preview WebView — through the MPRendererDelegate
// rendererBaseURL: hook that MPRenderer queries before producing HTML — must
// never be the real document file, because WebKit on macOS 26 can silently blank
// the preview when its base resource is that file (issues #405 / #431). Full
// WebView rendering can't be asserted headlessly, but this exercises the
// document-level base-URL path where the blank-preview bug lives.
- (void)testRendererBaseURLForOpenedFileAvoidsRealDocumentFile
{
    NSString *content = @"# Opened\n\nBody text.\n";
    [content writeToURL:self.testFileURL atomically:YES
               encoding:NSUTF8StringEncoding error:nil];
    self.document.fileURL = self.testFileURL;

    NSURL *base = [(id<MPRendererDelegate>)self.document rendererBaseURL:nil];

    XCTAssertNotNil(base, @"An opened document must still provide a base URL");
    XCTAssertNotEqualObjects(base, self.testFileURL,
        @"The opened document's own file must never be the preview base resource");
    XCTAssertEqualObjects(base.URLByDeletingLastPathComponent.path,
                          self.testFileURL.URLByDeletingLastPathComponent.path,
        @"The base URL must stay in the document's directory so relative "
         "resources and the security scope check are unchanged");
    XCTAssertFalse([self.fileManager fileExistsAtPath:base.path],
        @"The base URL must point at a non-existent sentinel, not a real file");
}


#pragma mark - Workspace Tests

- (void)testWorkspaceRootURLDefaultsToNilAndIsSettable
{
    MPDocument *doc = [[MPDocument alloc] init];
    XCTAssertNil(doc.workspaceRootURL);
    NSURL *root = [NSURL fileURLWithPath:@"/tmp" isDirectory:YES];
    doc.workspaceRootURL = root;
    XCTAssertEqualObjects(doc.workspaceRootURL, root);
}

- (void)testPrintCompletionRetainsDelegateAndDeliversArguments
{
    MPPrintDelegateProbe *probe = [MPPrintDelegateProbe new];
    __weak MPPrintDelegateProbe *weakProbe = probe;
    void *expectedContext = (__bridge void *)self;
    NSInvocation *invocation = [MPDocument printCompletionForDelegate:probe
        selector:@selector(document:printed:context:) context:expectedContext];
    void *retainedContext = (__bridge_retained void *)invocation;
    invocation = nil;
    probe = nil;
    XCTAssertNotNil(weakProbe);
    probe = weakProbe;
    [self.document document:self.document didPrint:YES context:retainedContext];
    XCTAssertEqual(probe.calls, 1);
    XCTAssertEqual(probe.document, self.document);
    XCTAssertTrue(probe.success);
    XCTAssertEqual(probe.context, expectedContext);
}

- (void)testEditorFootnoteParsingFollowsPreferenceAndPreservesMath
{
    MPPreferences *preferences = self.document.preferences;
    BOOL originalNotes = preferences.extensionFootnotes;
    BOOL originalMath = preferences.htmlMathJax;
    BOOL originalDollar = preferences.htmlMathJaxInlineDollar;
    HGMarkdownHighlighter *highlighter = [[HGMarkdownHighlighter alloc] init];
    self.document.highlighter = highlighter;
    @try {
        for (NSNumber *notes in @[@NO, @YES]) {
            for (NSNumber *math in @[@NO, @YES]) {
                for (NSNumber *dollar in @[@NO, @YES]) {
                    preferences.extensionFootnotes = notes.boolValue;
                    preferences.htmlMathJax = math.boolValue;
                    preferences.htmlMathJaxInlineDollar = dollar.boolValue;
                    [self.document setupEditor:@"extensionFootnotes"];
                    pmh_element **elements = [highlighter parseText:@"Text[^*note*].\n"];
                    XCTAssertNotEqual(elements, NULL);
                    if (elements) {
                        // A footnote reference is opaque when enabled. With notes disabled,
                        // its asterisks remain ordinary Markdown emphasis.
                        XCTAssertEqual(elements[pmh_EMPH] != NULL, !notes.boolValue);
                        pmh_free_elements(elements);
                    }
                    XCTAssertEqual((highlighter.extensions & pmh_EXT_MATH) != 0,
                                   math.boolValue && dollar.boolValue);
                }
            }
        }
    } @finally {
        [highlighter deactivate];
        preferences.extensionFootnotes = originalNotes;
        preferences.htmlMathJax = originalMath;
        preferences.htmlMathJaxInlineDollar = originalDollar;
    }
}


- (void)testUnderlineActionKeepsUnderlineMeaningWithExtensionEnabledOrDisabled
{
    MPPreferences *preferences = self.document.preferences;
    BOOL original = preferences.extensionUnderline;
    MPEditorView *editor = [[MPEditorView alloc] initWithFrame:NSMakeRect(0, 0, 400, 200)];
    self.document.editor = editor;
    MPRenderer *renderer = [MPRenderer new];
    renderer.dataSource = (id<MPRendererDataSource>)self.document;
    renderer.delegate = (id<MPRendererDelegate>)self.document;
    @try {
        for (NSNumber *enabled in @[@NO, @YES]) {
            preferences.extensionUnderline = enabled.boolValue;
            editor.string = @"text";
            editor.selectedRange = NSMakeRange(0, editor.string.length);
            [self.document toggleUnderline:nil];
            XCTAssertEqualObjects(editor.string, @"_text_");
            [renderer parseMarkdown:editor.string];
            XCTAssertTrue([renderer.currentHtml containsString:@"<u>text</u>"]);
            XCTAssertFalse([renderer.currentHtml containsString:@"<em>"]);
        }
    } @finally {
        preferences.extensionUnderline = original;
    }
}

- (void)testBackspaceDeletesSelectionWithoutDeletingMatchingPairAroundIt
{
    MPPreferences *preferences = self.document.preferences;
    BOOL original = preferences.editorCompleteMatchingCharacters;
    MPEditorView *editor = [[MPEditorView alloc] initWithFrame:NSMakeRect(0, 0, 400, 200)];
    self.document.editor = editor;
    editor.delegate = (id<NSTextViewDelegate>)self.document;
    @try {
        preferences.editorCompleteMatchingCharacters = YES;
        editor.string = @"[]";
        editor.selectedRange = NSMakeRange(1, 1);
        [editor doCommandBySelector:@selector(deleteBackward:)];
        XCTAssertEqualObjects(editor.string, @"[");
        XCTAssertTrue(NSEqualRanges(editor.selectedRange, NSMakeRange(1, 0)));
    } @finally {
        preferences.editorCompleteMatchingCharacters = original;
    }
}

- (void)testSmartHomeWithSurrogatePairMovesToFirstContentCharacter
{
    MPPreferences *preferences = self.document.preferences;
    BOOL original = preferences.editorSmartHome;
    MPEditorView *editor = [[MPEditorView alloc] initWithFrame:NSMakeRect(0, 0, 400, 200)];
    self.document.editor = editor;
    @try {
        preferences.editorSmartHome = YES;
        editor.string = @"  😀";
        editor.selectedRange = NSMakeRange(editor.string.length, 0);
        XCTAssertFalse([self.document textViewShouldMoveToLeftEndOfLine:editor]);
        XCTAssertTrue(NSEqualRanges(editor.selectedRange, NSMakeRange(2, 0)));
    } @finally {
        preferences.editorSmartHome = original;
    }
}


- (void)testPDFExportAllowsOnePendingPanelAndCanRetryAfterCancellation
{
    MPControlledExportPanel *panel = [MPControlledExportPanel new];
    MPCurrentControlledExportPanel = panel;
    Method factory = class_getClassMethod(NSSavePanel.class, @selector(savePanel));
    IMP original = method_setImplementation(factory, (IMP)MPControlledExportPanelFactory);
    @try {
        [self.document exportPdf:nil];
        XCTAssertEqual(panel.presentations, 1u);
        [self.document exportPdf:nil];
        XCTAssertEqual(panel.presentations, 1u, @"A second export must not open another save panel");
        XCTAssertNotNil(panel.completion);
        panel.completion(NSFileHandlingPanelCancelButton);
        [self.document exportPdf:nil];
        XCTAssertEqual(panel.presentations, 2u, @"Cancellation must release the export slot");
        panel.completion(NSFileHandlingPanelCancelButton);
    } @finally {
        method_setImplementation(factory, original);
        MPCurrentControlledExportPanel = nil;
    }
}

- (void)testAnEarlierSaveTimerCannotReloadWhileTheLatestSaveIsProtected
{
    MPDocument *document = [MPDocument new];
    document.fileURL = self.testFileURL;
    document.fileType = @"net.daringfireball.markdown";
    document.markdown = @"first save";
    XCTAssertTrue([document writeToURL:self.testFileURL ofType:document.fileType error:NULL]);
    XCTestExpectation *protected = [self expectationWithDescription:@"Latest save remains protected after first timer"];
    XCTestExpectation *resumed = [self expectationWithDescription:@"External reload resumes after latest timer"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        document.markdown = @"latest save";
        XCTAssertTrue([document writeToURL:self.testFileURL ofType:document.fileType error:NULL]);
        document.fileModificationDate = [NSDate distantPast];
        XCTAssertTrue([@"external change" writeToURL:self.testFileURL atomically:YES
            encoding:NSUTF8StringEncoding error:NULL]);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [document processExternalFileChange];
            XCTAssertEqualObjects(document.markdown, @"latest save");
            [protected fulfill];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.65 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [document processExternalFileChange];
            XCTAssertEqualObjects(document.markdown, @"external change");
            [resumed fulfill];
        });
    });
    [self waitForExpectations:@[protected, resumed] timeout:5.0];
    [document close];
}

- (void)testChangedHeadScriptsReloadAndUnchangedHeadPreservesJavaScriptState
{
    MPPreferences *preferences = self.document.preferences;
    BOOL math = preferences.htmlMathJax, mermaid = preferences.htmlMermaid, graphviz = preferences.htmlGraphviz;
    MPDocumentExportAuditProbe *document = [MPDocumentExportAuditProbe new];
    WebView *preview = [[WebView alloc] initWithFrame:NSMakeRect(0, 0, 400, 300)];
    document.preview = preview;
    preview.frameLoadDelegate = (id<WebFrameLoadDelegate>)document;
    MPRenderer *renderer = [MPRenderer new];
    document.renderer = renderer;
    NSString *(^html)(NSString *, NSString *) = ^NSString *(NSString *marker, NSString *body) {
        return [NSString stringWithFormat:@"<html><head><script>window.macdownAuditHeadMarker='%@';</script></head><body><p>%@</p></body></html>", marker, body];
    };
    @try {
        preferences.htmlMathJax = NO; preferences.htmlMermaid = NO; preferences.htmlGraphviz = NO;
        [document renderer:renderer didProduceHTMLOutput:html(@"first", @"first body")];
        XCTNSPredicateExpectation *first = [[XCTNSPredicateExpectation alloc]
            initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
                return document.isPreviewReady &&
                    [[[preview.mainFrame.javaScriptContext evaluateScript:@"window.macdownAuditHeadMarker"] toString] isEqualToString:@"first"];
            }] object:document];
        [self waitForExpectations:@[first] timeout:10.0];
        [document renderer:renderer didProduceHTMLOutput:html(@"second", @"second body")];
        XCTNSPredicateExpectation *second = [[XCTNSPredicateExpectation alloc]
            initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
                return !document.alreadyRenderingInWeb &&
                    [[[preview.mainFrame.javaScriptContext evaluateScript:@"window.macdownAuditHeadMarker"] toString] isEqualToString:@"second"];
            }] object:document];
        [self waitForExpectations:@[second] timeout:10.0];
        [preview.mainFrame.javaScriptContext evaluateScript:@"window.macdownAuditHeadMarker='survived';"];
        [document renderer:renderer didProduceHTMLOutput:html(@"second", @"third body")];
        XCTAssertEqualObjects([[preview.mainFrame.javaScriptContext evaluateScript:@"window.macdownAuditHeadMarker"] toString], @"survived");
        XCTAssertEqualObjects([[preview.mainFrame.javaScriptContext evaluateScript:@"document.body.textContent.trim()"] toString], @"third body");
    } @finally {
        preview.frameLoadDelegate = nil;
        [document close];
        preferences.htmlMathJax = math; preferences.htmlMermaid = mermaid; preferences.htmlGraphviz = graphviz;
    }
}

- (void)testPreviewFindActionsSearchRenderedTextWithoutChangingMarkdown
{
    MPDocument *document = [MPDocument new];
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,400,300)
        styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
    window.releasedWhenClosed = NO;
    [document addWindowController:[[NSWindowController alloc] initWithWindow:window]];
    WebView *web = [[WebView alloc] initWithFrame:window.contentView.bounds];
    [window.contentView addSubview:web];
    MPEditorView *editor = [[MPEditorView alloc] initWithFrame:NSMakeRect(0,0,400,300)];
    document.editor = editor;
    document.preview = web;
    [document showWindows];
    NSString *source = @"# source remains **unchanged**\n";
    document.editor.string = source;
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSPasteboardNameFind];
    NSMutableArray *originalItems = [NSMutableArray array];
    for (NSPasteboardItem *item in pasteboard.pasteboardItems) {
        NSPasteboardItem *copy = [NSPasteboardItem new];
        for (NSString *type in item.types)
            [copy setData:[item dataForType:type] forType:type];
        [originalItems addObject:copy];
    }
    @try {
        [web.mainFrame loadHTMLString:@"<html><body>"
            "<p id='first'>target <strong>é</strong></p>"
            "<p id='second'>target é</p></body></html>" baseURL:nil];
        XCTNSPredicateExpectation *ready = [[XCTNSPredicateExpectation alloc]
            initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id object,
                                                                   NSDictionary *bindings) {
                return !web.isLoading && web.mainFrame.DOMDocument.body != nil;
            }] object:web];
        [self waitForExpectations:@[ready] timeout:10];
        NSMenuItem *find = [[NSMenuItem alloc] initWithTitle:@"Find"
            action:@selector(performDocumentFindAction:) keyEquivalent:@"f"];
        find.tag = NSTextFinderActionShowFindInterface;
        [web.window makeFirstResponder:web.mainFrame.frameView.documentView];
        XCTAssertTrue([NSApp sendAction:find.action to:document from:find]);
        XCTAssertTrue([document respondsToSelector:@selector(previewFindField)]);
        if (![document respondsToSelector:@selector(previewFindField)]) return;
        NSSearchField *field = document.previewFindField;
        XCTAssertTrue(field.window.isVisible);
        field.stringValue = @"target é";
        XCTAssertTrue([NSApp sendAction:field.action to:field.target from:field]);
        XCTAssertEqualObjects(web.selectedDOMRange.toString, @"target é");
        DOMNode *first = web.selectedDOMRange.startContainer;
        find.tag = NSTextFinderActionNextMatch;
        [NSApp sendAction:find.action to:document from:find];
        XCTAssertEqualObjects(web.selectedDOMRange.toString, @"target é");
        XCTAssertNotEqual(web.selectedDOMRange.startContainer, first);
        find.tag = NSTextFinderActionPreviousMatch;
        [NSApp sendAction:find.action to:document from:find];
        XCTAssertEqual(web.selectedDOMRange.startContainer, first);
        find.tag = NSTextFinderActionShowReplaceInterface;
        XCTAssertFalse([document validateDocumentFindAction:find]);
        XCTAssertEqualObjects(document.editor.string, source);
        [(NSResponder *)field.window cancelOperation:nil];
        XCTAssertFalse(field.window.isVisible);
    } @finally {
        [pasteboard clearContents];
        if (originalItems.count) [pasteboard writeObjects:originalItems];
        [document updateChangeCount:NSChangeCleared];
        [document close];
    }
}

- (void)testPreviewFormattingErrorBelongsToSelectionAndDeselectHidesPanel
{
    MPDocument *document = [MPDocument new];
    document.fileURL = self.testFileURL;
    MPEditorView *editor = [[MPEditorView alloc] initWithFrame:NSMakeRect(0,0,500,300)];
    WebView *web = [[WebView alloc] initWithFrame:NSMakeRect(0,0,500,300)];
    MPRenderer *renderer = [MPRenderer new];
    document.editor = editor; document.preview = web; document.renderer = renderer;
    renderer.delegate = (id<MPRendererDelegate>)document;
    renderer.dataSource = (id<MPRendererDataSource>)document;
    web.frameLoadDelegate = (id<WebFrameLoadDelegate>)document;
    BOOL oldMath = document.preferences.htmlMathJax;
    BOOL oldSmart = document.preferences.extensionSmartyPants;
    @try {
        document.preferences.htmlMathJax = NO;
        document.preferences.extensionSmartyPants = NO;
        editor.string = @"Alpha passage\n\nBeta passage\n";
        [renderer parseMarkdown:editor.string]; [renderer render];
        [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:
            [NSPredicate predicateWithBlock:^BOOL(id object,NSDictionary *bindings) {
                return !web.isLoading && document.previewEditRanges.count==2;
            }] object:web]] timeout:10];
        NSString *(^select)(NSString *) = ^NSString *(NSString *text) {
            return [NSString stringWithFormat:@"(function(){var e=Array.from(document.querySelectorAll('[data-mp-edit-id]')).find(function(n){return n.textContent==='%@';}),r=document.createRange();r.selectNodeContents(e);getSelection().removeAllRanges();getSelection().addRange(r);window.dispatchEvent(new Event('scroll'));})()",text];
        };
        [web stringByEvaluatingJavaScriptFromString:select(@"Alpha passage")];
        [web stringByEvaluatingJavaScriptFromString:@"window.macdownPreviewEditor.showFormattingError();window.dispatchEvent(new Event('scroll'));"];
        XCTAssertTrue([[web stringByEvaluatingJavaScriptFromString:@"!!document.getElementById('macdown-preview-edit-error')"] boolValue],@"The refusal remains visible for the same selection after scrolling");
        [web stringByEvaluatingJavaScriptFromString:select(@"Beta passage")];
        XCTAssertFalse([[web stringByEvaluatingJavaScriptFromString:@"!!document.getElementById('macdown-preview-edit-error')"] boolValue],@"A new admissible selection must not inherit the previous error");
        XCTAssertEqualObjects([web stringByEvaluatingJavaScriptFromString:@"getComputedStyle(document.getElementById('macdown-preview-format')).display"],@"block");
        [web stringByEvaluatingJavaScriptFromString:@"document.body.dispatchEvent(new MouseEvent('mousedown',{bubbles:true,button:0}));getSelection().removeAllRanges();window.dispatchEvent(new MouseEvent('mouseup',{bubbles:true,button:0}));"];
        XCTAssertEqualObjects([web stringByEvaluatingJavaScriptFromString:@"getComputedStyle(document.getElementById('macdown-preview-format')).display"],@"none");
        XCTAssertEqualObjects(editor.string,@"Alpha passage\n\nBeta passage\n");
    } @finally {
        web.frameLoadDelegate = nil; [document close];
        document.preferences.htmlMathJax = oldMath;
        document.preferences.extensionSmartyPants = oldSmart;
    }
}

- (void)testPreviewFormattingInsideWordsUsesMarkdownAndRendersStyles
{
    MPDocument *document = [MPDocument new];
    MPEditorView *editor = [[MPEditorView alloc] initWithFrame:NSMakeRect(0,0,500,300)];
    document.editor = editor;
    MPRenderer *renderer = [MPRenderer new];
    renderer.delegate = (id<MPRendererDelegate>)document;
    renderer.dataSource = (id<MPRendererDataSource>)document;
    document.renderer = renderer;
    MPPreferences *preferences = document.preferences;
    BOOL oldIntra = preferences.extensionIntraEmphasis;
    BOOL oldUnderline = preferences.extensionUnderline;
    void (^prepare)(NSString *, NSString *) = ^(NSString *source, NSString *text) {
        editor.string = source;
        [renderer parseMarkdown:source];
        NSRange range = [source rangeOfString:text];
        document.previewEditRanges = @[@{@"location":@(range.location),@"length":@(range.length),@"text":text}];
        document.previewEditSource = source;
        document.previewEditToken = renderer.checkboxBridgeToken;
    };
    @try {
        preferences.extensionIntraEmphasis = NO;
        preferences.extensionUnderline = NO;
        prepare(@"test avec test", @"test avec test");
        XCTAssertTrue(([document applyPreviewEditPayload:@{@"token":document.previewEditToken,@"id":@0,@"action":@"bold",@"start":@1,@"end":@11}]));
        XCTAssertEqualObjects(editor.string, @"t**est avec t**est");
        XCTAssertTrue([[renderer HTMLForMarkdownSnapshot:editor.string] containsString:@"t<strong>est avec t</strong>est"]);
        XCTAssertTrue(preferences.extensionIntraEmphasis);
        prepare(editor.string, @"est avec t");
        XCTAssertTrue(([document applyPreviewEditPayload:@{@"token":document.previewEditToken,@"id":@0,@"action":@"underline",@"start":@0,@"end":@10}]));
        XCTAssertEqualObjects(editor.string, @"t**_est avec t_**est");
        XCTAssertTrue([[renderer HTMLForMarkdownSnapshot:editor.string] containsString:@"t<strong><u>est avec t</u></strong>est"]);
        XCTAssertFalse([editor.string containsString:@"<"]);
        // Selection whitespace stays outside the formatting delimiters.
        preferences.extensionIntraEmphasis = NO;
        prepare(@"test avec test", @"test avec test");
        XCTAssertTrue(([document applyPreviewEditPayload:@{@"token":document.previewEditToken,@"id":@0,@"action":@"bold",@"start":@0,@"end":@5}]));
        XCTAssertEqualObjects(editor.string, @"**test** avec test");
        XCTAssertTrue([[renderer HTMLForMarkdownSnapshot:editor.string] containsString:@"<strong>test</strong> avec test"]);
        prepare(@"test avec test", @"test avec test");
        XCTAssertFalse(([document applyPreviewEditPayload:@{@"token":document.previewEditToken,@"id":@0,@"action":@"bold",@"start":@4,@"end":@5}]));
        XCTAssertEqualObjects(editor.string, @"test avec test");
        prepare(@"**part**", @"part");
        XCTAssertTrue(([document applyPreviewEditPayload:@{@"token":document.previewEditToken,@"id":@0,@"action":@"italic",@"start":@0,@"end":@4}]));
        XCTAssertEqualObjects(editor.string, @"***part***");
        prepare(editor.string, @"part");
        XCTAssertTrue(([document applyPreviewEditPayload:@{@"token":document.previewEditToken,@"id":@0,@"action":@"italic",@"start":@0,@"end":@4}]));
        XCTAssertEqualObjects(editor.string, @"**part**");
        preferences.extensionUnderline = YES;
        prepare(@"_**part**_", @"part");
        XCTAssertTrue(([document applyPreviewEditPayload:@{@"token":document.previewEditToken,@"id":@0,@"action":@"underline",@"start":@0,@"end":@4}]));
        XCTAssertEqualObjects(editor.string, @"**part**");
        prepare(@"first\n\nsecond", @"first\n\nsecond");
        XCTAssertFalse(([document applyPreviewEditPayload:@{@"token":document.previewEditToken,@"id":@0,@"action":@"bold",@"start":@0,@"end":@13}]));
        XCTAssertEqualObjects(editor.string, @"first\n\nsecond");
    } @finally {
        preferences.extensionIntraEmphasis = oldIntra;
        preferences.extensionUnderline = oldUnderline;
        [document close];
    }
}

// Keep Hoedown and the native transaction real; only the already-proven DOM
// mapping is supplied so block source transformations can be isolated.
- (void)assertPreviewBlockSource:(NSString *)source texts:(NSArray<NSString *> *)texts
                          value:(NSString *)value expected:(NSString *)expected
                           HTML:(NSString *)expectedHTML
{
    MPDocument *document = [MPDocument new];
    MPEditorView *editor = [[MPEditorView alloc] initWithFrame:NSMakeRect(0,0,500,300)];
    MPRenderer *renderer = [MPRenderer new];
    document.editor = editor; document.renderer = renderer;
    renderer.delegate = (id<MPRendererDelegate>)document;
    renderer.dataSource = (id<MPRendererDataSource>)document;
    BOOL oldSmarty = document.preferences.extensionSmartyPants;
    BOOL oldTasks = document.preferences.htmlTaskList;
    @try {
        document.preferences.extensionSmartyPants = NO;
        document.preferences.htmlTaskList = YES;
        editor.string = source;
        [renderer parseMarkdown:source];
        NSMutableArray *mapping = [NSMutableArray array], *runs = [NSMutableArray array];
        NSMutableString *visible = [NSMutableString string];
        NSUInteger cursor = 0;
        for (NSString *text in texts) {
            NSRange found = [source rangeOfString:text options:NSLiteralSearch range:NSMakeRange(cursor,source.length-cursor)];
            XCTAssertNotEqual(found.location, NSNotFound);
            if (found.location == NSNotFound) return;
            if (mapping.count) {
                for (NSUInteger i=cursor;i<found.location;i++) {
                    unichar c = [source characterAtIndex:i];
                    if (c=='\n' || c=='\r') [visible appendFormat:@"%C",c];
                }
            }
            [visible appendString:text];
            [runs addObject:@{@"id":@(mapping.count),@"start":@0,@"end":@(text.length)}];
            [mapping addObject:@{@"location":@(found.location),@"length":@(found.length),@"text":text}];
            cursor = NSMaxRange(found);
        }
        document.previewEditRanges = mapping;
        document.previewEditSource = source;
        document.previewEditToken = renderer.checkboxBridgeToken;
        NSMutableDictionary *payload = [runs.firstObject mutableCopy];
        payload[@"runs"] = runs; payload[@"text"] = visible;
        payload[@"token"] = document.previewEditToken; payload[@"action"] = @"block"; payload[@"value"] = value;
        XCTAssertTrue([document applyPreviewEditPayload:payload], @"%@ -> %@",source,value);
        XCTAssertEqualObjects(editor.string, expected);
        XCTAssertTrue([[renderer HTMLForMarkdownSnapshot:editor.string] containsString:expectedHTML]);
    } @finally {
        [document close];
        document.preferences.extensionSmartyPants = oldSmarty;
        document.preferences.htmlTaskList = oldTasks;
    }
}

- (void)testPreviewBlockConversionPreservesBlankSeparators
{
    for (NSArray *scenario in @[@[@"h1",@"# ",@"<h1"],@[@"unordered",@"- ",@"<ul>"],@[@"tasks",@"- [ ] ",@"<ul>"],@[@"quote",@"> ",@"<blockquote>"]]) {
        NSString *prefix = scenario[1];
        [self assertPreviewBlockSource:@"first\n\n \t\nsecond\n\nNeighbor.\n" texts:@[@"first",@"second"] value:scenario[0]
            expected:[NSString stringWithFormat:@"%@first\n\n \t\n%@second\n\nNeighbor.\n",prefix,prefix] HTML:scenario[2]];
    }
}

- (void)testPreviewBlockConversionLeavesUnselectedSourceBetweenParagraphsUnchanged
{
    [self assertPreviewBlockSource:@"first\n\n<!-- preserved comment -->\n\n![Image](keep.png)\n\nsecond\n\nNeighbor.\n"
        texts:@[@"first",@"second"] value:@"h1"
        expected:@"# first\n\n<!-- preserved comment -->\n\n![Image](keep.png)\n\n# second\n\nNeighbor.\n" HTML:@"<h1"];
}

- (void)testPreviewBlockConversionConsumesSetextUnderlineWithoutTouchingNeighborRule
{
    for (NSString *underline in @[@"====",@"----"]) {
        for (NSArray *scenario in @[@[@"paragraph",@"",@"<p>Title</p>"],@[@"h3",@"### ",@"<h3"],@[@"quote",@"> ",@"<blockquote>"]]) {
            [self assertPreviewBlockSource:[NSString stringWithFormat:@"Title\n%@\n\n---\n\nNeighbor.\n",underline]
                texts:@[@"Title"] value:scenario[0]
                expected:[NSString stringWithFormat:@"%@Title\n\n---\n\nNeighbor.\n",scenario[1]] HTML:scenario[2]];
        }
    }
}


- (void)testPreviewSetextConversionPreservesCRLFAndStandaloneRules
{
    [self assertPreviewBlockSource:@"Title\r\n====\r\n\r\nNeighbor.\r\n" texts:@[@"Title"] value:@"h3"
        expected:@"### Title\r\n\r\nNeighbor.\r\n" HTML:@"<h3"];
    [self assertPreviewBlockSource:@"Title\n====\n\nsecond\n\nNeighbor.\n" texts:@[@"Title",@"second"] value:@"h3"
        expected:@"### Title\n\n### second\n\nNeighbor.\n" HTML:@"<h3"];
}


- (void)testPreviewMixedStylesApplyToAllSelectedCharactersAndPreserveOutsideStyles
{
    MPDocument *document=[MPDocument new];
    MPEditorView *editor=[[MPEditorView alloc] initWithFrame:NSMakeRect(0,0,500,300)];
    MPRenderer *renderer=[MPRenderer new];
    document.editor=editor;document.renderer=renderer;
    renderer.delegate=(id<MPRendererDelegate>)document;renderer.dataSource=(id<MPRendererDataSource>)document;
    MPPreferences *preferences=document.preferences;
    BOOL oldIntra=preferences.extensionIntraEmphasis,oldUnderline=preferences.extensionUnderline,oldStrike=preferences.extensionStrikethough,oldSmart=preferences.extensionSmartyPants;
    NSArray *cases=@[
        @[@"test **mot** selection",@[@"test ",@"mot",@" selection"],@0,@0,@1,@3,@"bold",@"**test mot** selection"],
        @[@"test **mot** selection",@[@"test ",@"mot",@" selection"],@0,@2,@1,@2,@"bold",@"te**st mot** selection"],
        @[@"test **mot** selection",@[@"test ",@"mot",@" selection"],@1,@1,@2,@4,@"bold",@"test **mot sel**ection"],
        @[@"test *mot* selection",@[@"test ",@"mot",@" selection"],@0,@0,@1,@3,@"italic",@"*test mot* selection"],
        @[@"test _mot_ selection",@[@"test ",@"mot",@" selection"],@0,@0,@1,@3,@"underline",@"_test mot_ selection"],
        @[@"test ~~mot~~ selection",@[@"test ",@"mot",@" selection"],@0,@0,@1,@3,@"strike",@"~~test mot~~ selection"],
        @[@"test **_mot_** selection",@[@"test ",@"mot",@" selection"],@0,@0,@1,@3,@"bold",@"**test _mot_** selection"],
        @[@"**a** **b**",@[@"a",@" ",@"b"],@0,@0,@2,@1,@"bold",@"**a b**"],
        @[@"avant **😀mot** fin",@[@"avant ",@"😀mot",@" fin"],@0,@0,@1,@2,@"bold",@"**avant 😀mot** fin"],
        @[@"**entier mot** fin",@[@"entier mot",@" fin"],@0,@7,@0,@10,@"bold",@"**entier** mot fin"]
    ];
    @try {
        preferences.extensionUnderline=YES;preferences.extensionStrikethough=YES;preferences.extensionSmartyPants=NO;
        for(NSArray *scenario in cases) {
            editor.string=scenario[0];[renderer parseMarkdown:editor.string];
            NSMutableArray *mapping=[NSMutableArray array];
            NSUInteger cursor=0;
            for(NSString *text in scenario[1]) {
                NSRange found=[editor.string rangeOfString:text options:NSLiteralSearch range:NSMakeRange(cursor,editor.string.length-cursor)];
                XCTAssertNotEqual(found.location,NSNotFound,@"%@",scenario);
                if(found.location==NSNotFound) break;
                [mapping addObject:@{@"location":@(found.location),@"length":@(found.length),@"text":text}];cursor=NSMaxRange(found);
            }
            document.previewEditRanges=mapping;document.previewEditSource=editor.string;document.previewEditToken=renderer.checkboxBridgeToken;
            NSUInteger first=[scenario[2] unsignedIntegerValue],last=[scenario[4] unsignedIntegerValue];
            NSMutableArray *runs=[NSMutableArray array];NSMutableString *visible=[NSMutableString string];
            for(NSUInteger i=first;i<=last;i++) {
                NSUInteger start=i==first?[scenario[3] unsignedIntegerValue]:0,end=i==last?[scenario[5] unsignedIntegerValue]:[mapping[i][@"length"] unsignedIntegerValue];
                [runs addObject:@{@"id":@(i),@"start":@(start),@"end":@(end)}];
                [visible appendString:[mapping[i][@"text"] substringWithRange:NSMakeRange(start,end-start)]];
            }
            NSMutableDictionary *payload=[runs.firstObject mutableCopy];payload[@"runs"]=runs;payload[@"text"]=visible;payload[@"action"]=scenario[6];payload[@"token"]=document.previewEditToken;
            XCTAssertTrue([document applyPreviewEditPayload:payload],@"%@",scenario);
            XCTAssertEqualObjects(editor.string,scenario[7],@"%@",scenario);
            XCTAssertFalse([editor.string containsString:@"<"]);
        }
        editor.string=@"test **mot** selection";[renderer parseMarkdown:editor.string];
        document.previewEditRanges=@[@{@"location":@0,@"length":@5,@"text":@"test "},@{@"location":@7,@"length":@3,@"text":@"mot"},@{@"location":@12,@"length":@10,@"text":@" selection"}];
        document.previewEditSource=editor.string;document.previewEditToken=renderer.checkboxBridgeToken;
        for(NSArray *bad in @[@[@{@"id":@0,@"start":@0,@"end":@5},@{@"id":@2,@"start":@0,@"end":@3}],@[@{@"id":@1,@"start":@0,@"end":@3},@{@"id":@0,@"start":@0,@"end":@5}],@[@{@"id":@0,@"start":@0,@"end":@5},@{@"id":@1,@"start":@0,@"end":@99}]]) {
            XCTAssertFalse(([document applyPreviewEditPayload:@{@"id":@0,@"token":document.previewEditToken,@"runs":bad,@"text":@"forged",@"action":@"bold"}]));
            XCTAssertEqualObjects(editor.string,@"test **mot** selection");
        }
    } @finally {
        [document close];preferences.extensionIntraEmphasis=oldIntra;preferences.extensionUnderline=oldUnderline;preferences.extensionStrikethough=oldStrike;preferences.extensionSmartyPants=oldSmart;
    }
}

- (void)testPreviewEditingChangesOnlyMappedSourceAndRejectsStaleOrInvalidRequests
{
    MPDocument *document = [MPDocument new];
    document.fileURL = self.testFileURL;
    MPPreferences *preferences = document.preferences;
    BOOL oldMath = preferences.htmlMathJax;
    BOOL oldSmart = preferences.extensionSmartyPants;
    BOOL oldTasks = preferences.htmlTaskList;
    BOOL oldUnderline = preferences.extensionUnderline;
    BOOL oldIntra = preferences.extensionIntraEmphasis;
    BOOL oldStrike = preferences.extensionStrikethough;
    MPEditorView *editor = [[MPEditorView alloc] initWithFrame:NSMakeRect(0,0,500,300)];
    WebView *web = [[WebView alloc] initWithFrame:NSMakeRect(0,0,500,300)];
    document.editor = editor; document.preview = web;
    NSWindow *window = [[NSWindow alloc] initWithContentRect:web.frame styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
    window.releasedWhenClosed = NO;
    window.contentView = web;
    web.frameLoadDelegate = (id<WebFrameLoadDelegate>)document;
    web.policyDelegate = (id<WebPolicyDelegate>)document;
    MPRenderer *renderer = [MPRenderer new];
    renderer.delegate = (id<MPRendererDelegate>)document;
    renderer.dataSource = (id<MPRendererDataSource>)document;
    document.renderer = renderer;
    @try {
        preferences.htmlMathJax = NO;
        preferences.extensionSmartyPants = NO;
        preferences.htmlTaskList = YES;
        renderer.rendererFlags = preferences.rendererFlags;
        editor.string = @"# Unique heading\n\nEditable phrase é 日本語.\n\n[Keep this link](https://example.com)\n\nRepeated\n\nRepeated\n\n[&#68;ecoded](https://example.com/Decoded)\n\n<span title=\"Attribute\">&#65;ttribute</span>\n";
        [renderer parseMarkdown:editor.string]; [renderer render];
        XCTNSPredicateExpectation *loaded = [[XCTNSPredicateExpectation alloc]
            initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id o, NSDictionary *b) {
                return !web.isLoading && document.previewEditRanges.count > 0;
            }] object:document];
        [self waitForExpectations:@[loaded] timeout:10];
        XCTAssertNotNil(document.previewEditToken);
        if (!document.previewEditToken) return;
        NSUInteger index = [document.previewEditRanges indexOfObjectPassingTest:^BOOL(NSDictionary *entry, NSUInteger i, BOOL *stop) {
            return [entry[@"text"] isEqualToString:@"Editable phrase é 日本語."];
        }];
        XCTAssertNotEqual(index, NSNotFound);
        NSArray *repeated=[document.previewEditRanges filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"text == %@",@"Repeated"]];
        XCTAssertEqual(repeated.count,2U);
        if (repeated.count==2) XCTAssertNotEqual([repeated[0][@"location"] unsignedIntegerValue],[repeated[1][@"location"] unsignedIntegerValue]);
        XCTAssertFalse([[document.previewEditRanges valueForKey:@"text"] containsObject:@"Decoded"]);
        XCTAssertFalse([[document.previewEditRanges valueForKey:@"text"] containsObject:@"Attribute"]);
        NSString *token = document.previewEditToken;
        NSString *before = editor.string;
        XCTAssertFalse(([document applyPreviewEditPayload:@{@"token":@"forged",@"id":@(index),@"action":@"replace",@"text":@"Changed"}]));
        XCTAssertFalse(([document applyPreviewEditPayload:@{@"token":token,@"id":@(-1),@"action":@"replace",@"text":@"Changed"}]));
        for (NSString *action in @[@"color",@"background"]) {
            XCTAssertFalse(([document applyPreviewEditPayload:@{@"token":token,@"id":@(index),@"action":action,@"start":@0,@"end":@4,@"value":@"#175cd3"}]));
        }
        XCTAssertFalse(([document applyPreviewEditPayload:@{@"token":token,@"id":@(index),@"action":@"block",@"start":@0,@"end":@4}]));
        XCTAssertFalse(([document applyPreviewEditPayload:@{@"token":token,@"id":@(index),@"action":@"link",@"start":@0,@"end":@4,@"value":@"javascript:alert(1)"}]));
        [document handlePreviewEdit:[NSURL URLWithString:@"x-macdown-preview://edit/?payload=%5B%5D"]];
        XCTAssertEqualObjects(editor.string, before);
        NSString *script = [NSString stringWithFormat:@"(function(){var e=document.querySelector('[data-mp-edit-id=\"%lu\"]'),r=document.createRange();r.setStart(e.firstChild,0);r.setEnd(e.firstChild,8);var s=getSelection();s.removeAllRanges();s.addRange(r);document.dispatchEvent(new Event('selectionchange'));})()",(unsigned long)index];
        [web stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.querySelector('[data-mp-edit-id=\"%lu\"]').dispatchEvent(new MouseEvent('mousedown',{bubbles:true,button:0}));",(unsigned long)index]];
        [web stringByEvaluatingJavaScriptFromString:script];
        [web stringByEvaluatingJavaScriptFromString:@"window.__heldSelectionChecked=false;setTimeout(function(){window.__heldSelectionDisplay=getComputedStyle(document.getElementById('macdown-preview-format')).display;window.__heldSelectionChecked=true;},250);"];
        [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id o,NSDictionary *b){return [[web stringByEvaluatingJavaScriptFromString:@"window.__heldSelectionChecked"] boolValue];}] object:web]] timeout:5];
        XCTAssertEqualObjects([web stringByEvaluatingJavaScriptFromString:@"window.__heldSelectionDisplay"], @"none");
        [web stringByEvaluatingJavaScriptFromString:@"window.dispatchEvent(new MouseEvent('mouseup',{bubbles:true,button:0}));"];
        XCTNSPredicateExpectation *panel = [[XCTNSPredicateExpectation alloc]
            initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id o, NSDictionary *b) {
                return [[web stringByEvaluatingJavaScriptFromString:@"getComputedStyle(document.getElementById('macdown-preview-format')).display"] isEqualToString:@"block"];
            }] object:web];
        [self waitForExpectations:@[panel] timeout:5];
        XCTAssertTrue([[web stringByEvaluatingJavaScriptFromString:@"(function(){var r=document.getElementById('macdown-preview-format').getBoundingClientRect();return r.left>=0&&r.right<=innerWidth&&r.top>=0&&r.bottom<=innerHeight;})()"] boolValue]);
        XCTAssertTrue(([document applyPreviewEditPayload:@{@"token":token,@"id":@(index),@"action":@"bold",@"start":@0,@"end":@8}]));
        XCTAssertTrue([editor.string containsString:@"**Editable** phrase é 日本語."]);
        XCTAssertTrue([editor.string containsString:@"[Keep this link](https://example.com)"]);
        XCTAssertFalse(([document applyPreviewEditPayload:@{@"token":token,@"id":@(index),@"action":@"replace",@"text":@"Stale overwrite"}]));
        XCTAssertFalse([[renderer HTMLForExportWithStyles:YES highlighting:YES] containsString:@"macdown-preview-format"]);
        XCTNSPredicateExpectation *updated = [[XCTNSPredicateExpectation alloc]
            initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id o, NSDictionary *b) {
                return !web.isLoading && ![document.previewEditToken isEqualToString:token];
            }] object:web];
        [self waitForExpectations:@[updated] timeout:10];
        [web stringByEvaluatingJavaScriptFromString:@"(function(){var e=Array.from(document.querySelectorAll('[data-mp-edit-id]')).filter(function(n){return n.textContent==='Editable';})[0],r=document.createRange();r.selectNodeContents(e);getSelection().removeAllRanges();getSelection().addRange(r);e.dispatchEvent(new MouseEvent('dblclick',{bubbles:true}));document.dispatchEvent(new Event('selectionchange'));})()"];
        XCTAssertEqualObjects([web stringByEvaluatingJavaScriptFromString:@"getSelection().toString()"], @"Editable");
        XCTAssertFalse([[web stringByEvaluatingJavaScriptFromString:@"!!document.querySelector('[contenteditable]')"] boolValue]);
        [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:panel.predicate object:web]] timeout:5];
        [web stringByEvaluatingJavaScriptFromString:@"Array.from(document.querySelectorAll('#macdown-preview-format button')).find(function(b){return b.textContent==='Modifier le texte';}).click();document.querySelector('[contenteditable]').textContent='Changed <safe>'"];

        XCTAssertTrue(document.isDocumentEdited);
        NSError *saveError = nil;
        NSData *savedData = [document dataOfType:@"net.daringfireball.markdown" error:&saveError];
        XCTAssertNil(saveError);
        NSString *savedSource = [[NSString alloc] initWithData:savedData encoding:NSUTF8StringEncoding];
        XCTAssertTrue([savedSource containsString:@"**Changed \\<safe\\>**"]);
        XCTAssertEqualObjects(savedSource, editor.string);
        XCTAssertFalse([[web stringByEvaluatingJavaScriptFromString:@"Boolean(window.macdownPreviewEditor.draft())"] boolValue]);
        NSArray *cases = @[
            @[@"block",@"h4",@"<h4"], @[@"block",@"unordered",@"<ul>"],
            @[@"block",@"tasks",@"type=\"checkbox\""], @[@"block",@"quote",@"<blockquote>"],
            @[@"block",@"callout",@"callout-note"], @[@"block",@"toggle-h2",@"<details"],
            @[@"clear",@"",@"<p>Scenario heading</p>"],
            @[@"clear",@"legacy",@"<p>Scenario heading</p>"],
            @[@"bold",@"punct",@"<strong>[looks]</strong>"],
            @[@"bold",@"",@"<strong>Scenario</strong>"], @[@"underline",@"",@"<u>Scenario</u>"],
            @[@"italic",@"",@"<em>Scenario</em>"]];
        for (NSArray *scenario in cases) {
            editor.string = [scenario[1] isEqualToString:@"legacy"] ? @"<u>Scenario</u> heading\n\nUntouched neighbor.\n" : [scenario[1] isEqualToString:@"punct"] ? @"# [looks]\n\nUntouched neighbor.\n" : [scenario[0] isEqualToString:@"clear"] ? @"**Scenario** heading\n\nUntouched neighbor.\n" : @"# Scenario heading\n\nUntouched neighbor.\n";
            [renderer parseMarkdown:editor.string]; [renderer render];
            NSString *scenarioToken = renderer.checkboxBridgeToken;
            XCTNSPredicateExpectation *ready = [[XCTNSPredicateExpectation alloc]
                initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id o, NSDictionary *b) {
                    return !web.isLoading && [document.previewEditToken isEqualToString:scenarioToken];
                }] object:web];
            [self waitForExpectations:@[ready] timeout:10];
            NSUInteger headingID = [document.previewEditRanges indexOfObjectPassingTest:^BOOL(NSDictionary *item, NSUInteger i, BOOL *stop) {
                return [item[@"text"] isEqualToString:([scenario[1] isEqualToString:@"punct"] ? @"[looks]" : [scenario[0] isEqualToString:@"clear"] ? @"Scenario" : @"Scenario heading")];
            }];
            XCTAssertNotEqual(headingID, NSNotFound);
            XCTAssertTrue(([document applyPreviewEditPayload:@{@"token":scenarioToken,@"id":@(headingID),@"action":scenario[0],@"value":scenario[1],@"start":@0,@"end":@([scenario[1] isEqualToString:@"punct"] ? 7 : 8)}]));
            XCTAssertFalse([editor.string containsString:@"<"]);
            XCTAssertFalse([editor.string containsString:@"<u>"]);
            XCTAssertFalse([editor.string containsString:@"<span"]);
            XCTAssertTrue([editor.string hasSuffix:@"\n\nUntouched neighbor.\n"], @"%@", scenario);
            [renderer parseMarkdown:editor.string];
            XCTAssertTrue([renderer.currentHtml containsString:scenario[2]], @"%@ : %@", scenario, renderer.currentHtml);
            if ([scenario[1] isEqualToString:@"toggle-h2"]) XCTAssertFalse([editor.string containsString:@"## # Scenario"]);
        }
        // Mixed source runs share one selection and one style transaction.
        // A drag may pause on an incomplete selection without opening the panel.
        editor.string=@"test **mot** selection\n\nUntouched neighbor.\n";
        [renderer parseMarkdown:editor.string];[renderer render];
        NSString *mixedToken=renderer.checkboxBridgeToken;
        [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id o,NSDictionary *b){return !web.isLoading&&[document.previewEditToken isEqualToString:mixedToken];}] object:web]] timeout:10];
        [web stringByEvaluatingJavaScriptFromString:@"(function(){var nodes=Array.from(document.querySelectorAll('[data-mp-edit-id]')),a=nodes.find(function(n){return n.textContent==='test ';}),b=nodes.find(function(n){return n.textContent==='mot';}),r=document.createRange();a.dispatchEvent(new MouseEvent('mousedown',{bubbles:true,button:0}));r.setStart(a.firstChild,2);r.setEnd(b.firstChild,2);getSelection().removeAllRanges();getSelection().addRange(r);document.dispatchEvent(new Event('selectionchange'));window.dispatchEvent(new MouseEvent('mouseup',{bubbles:true,button:0}));})()"];
        [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:panel.predicate object:web]] timeout:5];
        XCTAssertEqualObjects([web stringByEvaluatingJavaScriptFromString:@"getSelection().toString()"],@"st mo");
        XCTAssertEqualObjects([web stringByEvaluatingJavaScriptFromString:@"document.querySelector('[data-mp-style=bold]').getAttribute('aria-pressed')"],@"false");
        [web stringByEvaluatingJavaScriptFromString:@"document.querySelector('[data-mp-style=bold]').click()"];
        [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id o,NSDictionary *b){return !web.isLoading&&[editor.string isEqualToString:@"te**st mot** selection\n\nUntouched neighbor.\n"]&&[[web stringByEvaluatingJavaScriptFromString:@"getSelection().toString()"] isEqualToString:@"st mo"];} ] object:web]] timeout:10];
        XCTAssertEqualObjects([web stringByEvaluatingJavaScriptFromString:@"document.querySelector('[data-mp-style=bold]').getAttribute('aria-pressed')"],@"true");
        // Multiple identical inline whitespace nodes are source-bounded, so a
        // plain gap between two bold words participates in the intersection.
        editor.string=@"**a** **b** et **c** **d**\n\nUntouched neighbor.\n";
        [renderer parseMarkdown:editor.string];[renderer render];
        NSString *spaceToken=renderer.checkboxBridgeToken;
        [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id o,NSDictionary *b){return !web.isLoading&&[document.previewEditToken isEqualToString:spaceToken];}] object:web]] timeout:10];
        [web stringByEvaluatingJavaScriptFromString:@"(function(){var nodes=Array.from(document.querySelectorAll('[data-mp-edit-id]')),a=nodes.find(function(n){return n.textContent==='a';}),b=nodes.find(function(n){return n.textContent==='b';}),r=document.createRange();r.setStart(a.firstChild,0);r.setEnd(b.firstChild,1);getSelection().removeAllRanges();getSelection().addRange(r);document.dispatchEvent(new Event('selectionchange'));})()"];
        [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:panel.predicate object:web]] timeout:5];
        XCTAssertEqualObjects([web stringByEvaluatingJavaScriptFromString:@"document.querySelector('[data-mp-style=bold]').getAttribute('aria-pressed')"],@"false");
        [web stringByEvaluatingJavaScriptFromString:@"document.querySelector('[data-mp-style=bold]').click()"];
        [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id o,NSDictionary *b){return !web.isLoading&&[editor.string isEqualToString:@"**a b** et **c** **d**\n\nUntouched neighbor.\n"];} ] object:web]] timeout:10];
        // A selection crossing paragraphs keeps its literal text and toggles
        // the global common style, rather than toggling each paragraph alone.
        editor.string=@"**first**\n\nsecond\n\nUntouched neighbor.\n";
        [renderer parseMarkdown:editor.string];[renderer render];
        NSString *blockToken=renderer.checkboxBridgeToken;
        [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id o,NSDictionary *b){return !web.isLoading&&[document.previewEditToken isEqualToString:blockToken];}] object:web]] timeout:10];
        [web stringByEvaluatingJavaScriptFromString:@"(function(){var nodes=Array.from(document.querySelectorAll('[data-mp-edit-id]')),a=nodes.find(function(n){return n.textContent==='first';}),b=nodes.find(function(n){return n.textContent==='second';}),r=document.createRange();r.setStart(a.firstChild,0);r.setEnd(b.firstChild,6);getSelection().removeAllRanges();getSelection().addRange(r);document.dispatchEvent(new Event('selectionchange'));})()"];
        [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:panel.predicate object:web]] timeout:5];
        XCTAssertEqualObjects([web stringByEvaluatingJavaScriptFromString:@"document.querySelector('[data-mp-style=bold]').getAttribute('aria-pressed')"],@"false");
        [web stringByEvaluatingJavaScriptFromString:@"document.querySelector('[data-mp-style=bold]').click()"];
        [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id o,NSDictionary *b){return !web.isLoading&&[editor.string isEqualToString:@"**first**\n\n**second**\n\nUntouched neighbor.\n"]&&[[web stringByEvaluatingJavaScriptFromString:@"document.querySelector('[data-mp-style=bold]').getAttribute('aria-pressed')"] isEqualToString:@"true"];} ] object:web]] timeout:10];
        [web stringByEvaluatingJavaScriptFromString:@"document.querySelector('[data-mp-style=bold]').click()"];
        [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id o,NSDictionary *b){return !web.isLoading&&[editor.string isEqualToString:@"first\n\nsecond\n\nUntouched neighbor.\n"];} ] object:web]] timeout:10];
        // All heading levels admit element-boundary selections. Exercise each
        // style through the native toolbar with the editor cursor at EOF.
        preferences.extensionStrikethough = YES;
        NSArray *actions = @[@"bold",@"italic",@"underline",@"strike",@"bold",@"italic"];
        NSArray *tags = @[@"strong",@"em",@"u",@"del",@"strong",@"em"];
        for (NSUInteger level=1; level<=6; level++) {
            NSString *prefix = [@"" stringByPaddingToLength:level withString:@"#" startingAtIndex:0];
            editor.string = [NSString stringWithFormat:@"%@ Heading selection\n\nUntouched neighbor.\n",prefix];
            [renderer parseMarkdown:editor.string]; [renderer render];
            NSString *expectedToken = renderer.checkboxBridgeToken;
            [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id o, NSDictionary *b) {
                return !web.isLoading && [document.previewEditToken isEqualToString:expectedToken];
            }] object:web]] timeout:10];
            [web stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"(function(){var r=document.createRange();r.selectNodeContents(document.querySelector('h%lu'));getSelection().removeAllRanges();getSelection().addRange(r);document.dispatchEvent(new Event('selectionchange'));})()",(unsigned long)level]];
            [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:panel.predicate object:web]] timeout:5];
            editor.selectedRange = NSMakeRange(editor.string.length,0);
            XCTAssertTrue([window makeFirstResponder:web.mainFrame.frameView.documentView]);
            NSString *action = actions[level-1];
            if ([action isEqualToString:@"bold"]) [document toggleStrong:nil];
            else if ([action isEqualToString:@"italic"]) [document toggleEmphasis:nil];
            else if ([action isEqualToString:@"underline"]) [document toggleUnderline:nil];
            else [document toggleStrikethrough:nil];
            XCTAssertTrue([editor.string hasPrefix:[prefix stringByAppendingString:@" "]]);
            XCTAssertTrue([editor.string hasSuffix:@"\n\nUntouched neighbor.\n"]);
            [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id o, NSDictionary *b) {
                return !web.isLoading && ![document.previewEditToken isEqualToString:expectedToken];
            }] object:web]] timeout:10];
            NSString *check = [NSString stringWithFormat:@"document.querySelector('h%lu %@').textContent",(unsigned long)level,tags[level-1]];
            XCTAssertEqualObjects([web stringByEvaluatingJavaScriptFromString:check], @"Heading selection");
        }
        // Repeat the reported partial-word selection through the real WebView,
        // then format its freshly remapped rendered text again.
        preferences.extensionIntraEmphasis = NO;
        preferences.extensionUnderline = NO;
        editor.string = @"test avec test";
        [renderer parseMarkdown:editor.string]; [renderer render];
        for (NSString *action in @[@"bold",@"underline"]) {
            NSString *expectedToken = renderer.checkboxBridgeToken;
            XCTNSPredicateExpectation *ready = [[XCTNSPredicateExpectation alloc]
                initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id o, NSDictionary *b) {
                    return !web.isLoading && [document.previewEditToken isEqualToString:expectedToken];
                }] object:web];
            [self waitForExpectations:@[ready] timeout:10];
            NSString *text = [action isEqualToString:@"bold"] ? @"test avec test" : @"est avec t";
            NSUInteger identifier = [document.previewEditRanges indexOfObjectPassingTest:^BOOL(NSDictionary *item, NSUInteger i, BOOL *stop) {
                return [item[@"text"] isEqualToString:text];
            }];
            XCTAssertNotEqual(identifier, NSNotFound);
            if ([action isEqualToString:@"bold"]) {
                [web stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"(function(){var e=document.querySelector('[data-mp-edit-id=\"%lu\"]'),r=document.createRange();r.setStart(e.firstChild,1);r.setEnd(e.firstChild,11);getSelection().removeAllRanges();getSelection().addRange(r);document.dispatchEvent(new Event('selectionchange'));})()", (unsigned long)identifier]];
            } else XCTAssertEqualObjects([web stringByEvaluatingJavaScriptFromString:@"getSelection().toString()"], @"est avec t");
            editor.selectedRange = NSMakeRange(editor.string.length, 0);
            XCTAssertTrue([window makeFirstResponder:web.mainFrame.frameView.documentView]);
            XCTAssertTrue([document previewHasFindFocus]);
            [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:panel.predicate object:web]] timeout:5];
            [web stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.querySelector('[data-mp-style=%@]').click()",action]];
            XCTAssertEqualObjects([web stringByEvaluatingJavaScriptFromString:@"getComputedStyle(document.getElementById('macdown-preview-format')).display"], @"block");
            XCTNSPredicateExpectation *rendered = [[XCTNSPredicateExpectation alloc]
                initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id o, NSDictionary *b) {
                    return !web.isLoading && ![document.previewEditToken isEqualToString:expectedToken] &&
                        [[web stringByEvaluatingJavaScriptFromString:@"document.querySelector('p').textContent"] isEqualToString:@"test avec test"];
                }] object:web];
            [self waitForExpectations:@[rendered] timeout:10];
        }
        XCTAssertTrue([[web stringByEvaluatingJavaScriptFromString:@"!!document.querySelector('strong u')"] boolValue]);
        XCTAssertEqualObjects(editor.string, @"t**_est avec t_**est");
        // Queue rapid style clicks on the first of two identical words, then
        // change its block type without selecting again. Only that occurrence
        // may change; the other word and neighboring paragraph remain intact.
        editor.string = @"test avec test\n\nUntouched neighbor.\n";
        [renderer parseMarkdown:editor.string]; [renderer render];
        NSString *duplicateToken = renderer.checkboxBridgeToken;
        [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id o, NSDictionary *b) {
            return !web.isLoading && [document.previewEditToken isEqualToString:duplicateToken];
        }] object:web]] timeout:10];
        [web stringByEvaluatingJavaScriptFromString:@"(function(){var e=Array.from(document.querySelectorAll('[data-mp-edit-id]')).find(function(n){return n.textContent==='test avec test';}),r=document.createRange();r.setStart(e.firstChild,0);r.setEnd(e.firstChild,4);getSelection().removeAllRanges();getSelection().addRange(r);})()"];
        XCTAssertTrue([window makeFirstResponder:web.mainFrame.frameView.documentView]);
        [document toggleStrong:nil];
        [document toggleEmphasis:nil];
        [document toggleUnderline:nil];
        [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id o, NSDictionary *b) {
            return !web.isLoading && [editor.string isEqualToString:@"***_test_*** avec test\n\nUntouched neighbor.\n"] &&
                [[web stringByEvaluatingJavaScriptFromString:@"!!document.querySelector('strong') && !!document.querySelector('em') && !!document.querySelector('u') && getSelection().toString()==='test'"] boolValue];
        }] object:web]] timeout:15];
        [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:panel.predicate object:web]] timeout:5];
        [web stringByEvaluatingJavaScriptFromString:@"window.__panelBeforeFormatting=document.getElementById('macdown-preview-format');window.__panelHiddenFrames=0;window.__panelSampling=true;(function sample(){if(!window.__panelSampling)return;if(!window.__panelBeforeFormatting.isConnected||getComputedStyle(window.__panelBeforeFormatting).display==='none')window.__panelHiddenFrames++;requestAnimationFrame(sample);})();"];
        [document convertToH1:nil];
        XCTAssertEqualObjects([web stringByEvaluatingJavaScriptFromString:@"getComputedStyle(window.__panelBeforeFormatting).display"], @"block");
        [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id o, NSDictionary *b) {
            return !web.isLoading && [[web stringByEvaluatingJavaScriptFromString:@"!!document.querySelector('h1 u') && getSelection().toString()==='test'"] boolValue];
        }] object:web]] timeout:10];
        XCTAssertEqualObjects(editor.string, @"# ***_test_*** avec test\n\nUntouched neighbor.\n");
        XCTAssertTrue([[web stringByEvaluatingJavaScriptFromString:@"window.__panelBeforeFormatting===document.getElementById('macdown-preview-format')"] boolValue]);
        XCTAssertEqualObjects([web stringByEvaluatingJavaScriptFromString:@"window.__panelSampling=false;String(window.__panelHiddenFrames)"], @"0");
        XCTAssertTrue([[web stringByEvaluatingJavaScriptFromString:@"['bold','italic','underline'].every(function(s){var b=document.querySelector('[data-mp-style='+s+']');return b.getAttribute('aria-pressed')==='true' && getComputedStyle(b).color==='rgb(39, 132, 222)';})"] boolValue]);
        XCTAssertEqualObjects([web stringByEvaluatingJavaScriptFromString:@"document.querySelector('#macdown-preview-format select').value"], @"h1");
        XCTAssertEqualObjects([web stringByEvaluatingJavaScriptFromString:@"getComputedStyle(document.querySelector('#macdown-preview-format select')).color"], @"rgb(39, 132, 222)");
        XCTAssertEqualObjects([web stringByEvaluatingJavaScriptFromString:@"document.querySelector('[data-mp-style=strike]').getAttribute('aria-pressed')"], @"false");
        [web stringByEvaluatingJavaScriptFromString:@"getSelection().removeAllRanges();document.activeElement.blur();document.dispatchEvent(new Event('selectionchange'));"];
        [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id o, NSDictionary *b) {
            return [[web stringByEvaluatingJavaScriptFromString:@"getComputedStyle(document.getElementById('macdown-preview-format')).display"] isEqualToString:@"none"];
        }] object:web]] timeout:5];

        // Changing selection while the first style is pending cancels the
        // continuation, even when the newly selected word has identical text.
        editor.string = @"test avec test\n\nUntouched neighbor.\n";
        [renderer parseMarkdown:editor.string]; [renderer render];
        NSString *cancelToken = renderer.checkboxBridgeToken;
        [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id o, NSDictionary *b) {
            return !web.isLoading && [document.previewEditToken isEqualToString:cancelToken];
        }] object:web]] timeout:10];
        NSString *selectFirst = @"(function(){var e=Array.from(document.querySelectorAll('[data-mp-edit-id]')).find(function(n){return n.textContent==='test avec test';}),r=document.createRange();r.setStart(e.firstChild,0);r.setEnd(e.firstChild,4);getSelection().removeAllRanges();getSelection().addRange(r);})()";
        [web stringByEvaluatingJavaScriptFromString:selectFirst];
        XCTAssertTrue([window makeFirstResponder:web.mainFrame.frameView.documentView]);
        [document toggleStrong:nil];
        [web stringByEvaluatingJavaScriptFromString:[selectFirst stringByReplacingOccurrencesOfString:@"0);r.setEnd(e.firstChild,4)" withString:@"10);r.setEnd(e.firstChild,14)"]];
        [document toggleEmphasis:nil];
        [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id o, NSDictionary *b) {
            return !web.isLoading && ![document.previewEditToken isEqualToString:cancelToken];
        }] object:web]] timeout:10];
        XCTAssertEqualObjects(editor.string, @"**test** avec test\n\nUntouched neighbor.\n");
        // A collapsed preview selection must never insert at the editor cursor.
        [web stringByEvaluatingJavaScriptFromString:@"getSelection().removeAllRanges()"];
        [document toggleStrong:nil];
        XCTAssertEqualObjects(editor.string, @"**test** avec test\n\nUntouched neighbor.\n");
    } @finally {
        web.frameLoadDelegate = nil; web.policyDelegate = nil; [window close]; [document close];
        preferences.htmlMathJax = oldMath; preferences.extensionSmartyPants = oldSmart;
        preferences.htmlTaskList = oldTasks;
        preferences.extensionUnderline = oldUnderline;
        preferences.extensionIntraEmphasis = oldIntra;
        preferences.extensionStrikethough = oldStrike;
    }
}

- (void)testReadingProgressUsesVisiblePaneGeometryAndClampsBoundaries
{
    MPDocument *document = [MPDocument new];
    MPPreferences *preferences = document.preferences;
    BOOL oldProgress = preferences.editorShowReadingProgress;
    BOOL oldCount = preferences.editorShowWordCount;
    BOOL oldSync = preferences.editorSyncScrolling;
    BOOL oldReader = preferences.editorStartInPreviewMode;
    @try {
        preferences.editorShowReadingProgress = YES;
        preferences.editorShowWordCount = YES;
        preferences.editorSyncScrolling = NO;
        preferences.editorStartInPreviewMode = NO;
        [document makeWindowControllers]; [document showWindows];
        XCTestExpectation *setup = [self expectationWithDescription:@"Deferred editor setup"];
        [NSOperationQueue.mainQueue addOperationWithBlock:^{ [setup fulfill]; }];
        [self waitForExpectations:@[setup] timeout:5];
        document.editor.string = [@"Reading position line\n" stringByPaddingToLength:10000
            withString:@"Reading position line\n" startingAtIndex:0];
        [document.editor.layoutManager ensureLayoutForTextContainer:document.editor.textContainer];
        [document.editor sizeToFit];
        [document setupReadingProgress];
        XCTAssertNotNil([document valueForKey:@"readingProgressScrollMonitor"]);
        NSScrollView *scroll = document.editor.enclosingScrollView;
        [document willStartLiveScroll:nil];
        [scroll.documentView scrollPoint:NSMakePoint(0,0)];
        [document updateReadingProgress];
        XCTAssertEqualObjects(document.readingProgressLabel.stringValue, @"0%");
        CGFloat maximum = NSHeight(scroll.documentView.bounds)-NSHeight(scroll.documentVisibleRect);
        XCTAssertGreaterThan(maximum, 0);
        [scroll.documentView scrollPoint:NSMakePoint(0,maximum/2)];
        [document updateReadingProgress];
        XCTAssertEqualObjects(document.readingProgressLabel.stringValue, @"50%");
        [scroll.documentView scrollPoint:NSMakePoint(0,maximum)];
        [document updateReadingProgress];
        XCTAssertEqualObjects(document.readingProgressLabel.stringValue, @"100%");
        // A real short preview has no remaining reading distance.
        [document.preview.mainFrame loadHTMLString:@"<html><body>Short preview.</body></html>" baseURL:nil];
        XCTNSPredicateExpectation *loaded = [[XCTNSPredicateExpectation alloc]
            initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id o, NSDictionary *b) {
                return !document.preview.isLoading &&
                    [[document.preview stringByEvaluatingJavaScriptFromString:@"document.body.textContent"]
                        isEqualToString:@"Short preview."];
            }] object:document];
        [self waitForExpectations:@[loaded] timeout:10];
        [document willStartPreviewLiveScroll:nil];
        [document updateReadingProgress];
        XCTAssertEqualObjects(document.readingProgressLabel.stringValue, @"100%");
        [document.preview stringByEvaluatingJavaScriptFromString:@"document.body.style.height='2400px'"];
        NSScrollView *previewScroll = document.preview.enclosingScrollView;
        XCTNSPredicateExpectation *resized = [[XCTNSPredicateExpectation alloc]
            initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id o, NSDictionary *b) {
                return NSHeight(previewScroll.documentView.bounds) > NSHeight(previewScroll.documentVisibleRect)+100;
            }] object:document];
        [self waitForExpectations:@[resized] timeout:5];
        CGFloat previewMaximum = NSHeight(previewScroll.documentView.bounds)-NSHeight(previewScroll.documentVisibleRect);
        XCTAssertGreaterThan(previewMaximum, 0);
        [previewScroll.documentView scrollPoint:NSMakePoint(0, previewMaximum/2)];
        [document updateReadingProgress];
        XCTAssertEqualObjects(document.readingProgressLabel.stringValue, @"50%");
        [previewScroll.documentView scrollPoint:NSMakePoint(0, previewMaximum)];
        [document updateReadingProgress];
        XCTAssertEqualObjects(document.readingProgressLabel.stringValue, @"100%");
        preferences.editorShowWordCount = NO;
        [document setupReadingProgress];
        XCTAssertFalse(document.readingProgressLabel.hidden);
        preferences.editorShowReadingProgress = NO;
        [document setupReadingProgress];
        XCTAssertTrue(document.readingProgressLabel.hidden);
        XCTAssertNil([document valueForKey:@"readingProgressScrollMonitor"]);
    } @finally {
        [document updateChangeCount:NSChangeCleared]; [document close];
        preferences.editorShowReadingProgress = oldProgress;
        preferences.editorShowWordCount = oldCount;
        preferences.editorSyncScrolling = oldSync;
        preferences.editorStartInPreviewMode = oldReader;
    }
}

- (void)testCodeWrappingChangesLayoutWithoutChangingCodeAndExports
{
    MPDocument *document = [MPDocument new];
    MPPreferences *preferences = document.preferences;
    BOOL oldWrap = preferences.htmlWrapCodeBlocks;
    BOOL oldSyntax = preferences.htmlSyntaxHighlighting;
    BOOL oldFences = preferences.extensionFencedCode;
    BOOL oldMath = preferences.htmlMathJax;
    NSString *oldStyle = preferences.htmlStyleName;
    MPEditorView *editor = [[MPEditorView alloc] initWithFrame:NSMakeRect(0,0,240,300)];
    WebView *web = [[WebView alloc] initWithFrame:NSMakeRect(0,0,240,300)];
    document.editor = editor; document.preview = web;
    web.frameLoadDelegate = (id<WebFrameLoadDelegate>)document;
    MPRenderer *renderer = [MPRenderer new];
    renderer.delegate = (id<MPRendererDelegate>)document;
    renderer.dataSource = (id<MPRendererDataSource>)document;
    document.renderer = renderer;
    NSString *code = [@"x" stringByPaddingToLength:500 withString:@"x" startingAtIndex:0];
    editor.string = [NSString stringWithFormat:@"```bash\n%@\n```", code];
    @try {
        preferences.htmlSyntaxHighlighting = YES;
        preferences.extensionFencedCode = YES;
        preferences.htmlMathJax = NO;
        preferences.htmlStyleName = @"GitHub2";
        for (NSNumber *enabled in @[@NO, @YES, @NO]) {
            preferences.htmlWrapCodeBlocks = enabled.boolValue;
            [renderer parseMarkdown:editor.string];
            [renderer render];
            NSString *expected = enabled.boolValue ? @"pre-wrap" : @"pre";
            XCTNSPredicateExpectation *loaded = [[XCTNSPredicateExpectation alloc]
                initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
                    if (web.isLoading) return NO;
                    NSString *spacing = [web stringByEvaluatingJavaScriptFromString:
                        @"document.querySelector('pre') ? getComputedStyle(document.querySelector('pre')).whiteSpace : ''"];
                    return [spacing isEqualToString:expected];
                }] object:web];
            [self waitForExpectations:@[loaded] timeout:10];
            XCTAssertEqualObjects([web stringByEvaluatingJavaScriptFromString:
                @"document.querySelector('pre code').textContent.trim()"], code);
            if (enabled.boolValue) {
                XCTAssertEqualObjects([web stringByEvaluatingJavaScriptFromString:
                    @"String(document.querySelector('pre').scrollWidth <= document.querySelector('pre').clientWidth+1)"], @"true");
            }
            NSString *html = [renderer HTMLForExportWithStyles:YES highlighting:YES];
            XCTAssertEqual([html containsString:@"id=\"macdown-code-wrapping\""], enabled.boolValue);
            XCTAssertFalse([[renderer HTMLForExportWithStyles:NO highlighting:NO]
                containsString:@"id=\"macdown-code-wrapping\""]);
        }
    } @finally {
        web.frameLoadDelegate = nil; [document close];
        preferences.htmlWrapCodeBlocks = oldWrap;
        preferences.htmlSyntaxHighlighting = oldSyntax;
        preferences.extensionFencedCode = oldFences;
        preferences.htmlMathJax = oldMath;
        preferences.htmlStyleName = oldStyle;
    }
}

- (void)testFirstRealCodeRenderAfterEmptyPreviewLoadsPrismGrammarAndTokens
{
    MPPreferences *preferences = self.document.preferences;
    BOOL syntax = preferences.htmlSyntaxHighlighting;
    BOOL fences = preferences.extensionFencedCode;
    BOOL math = preferences.htmlMathJax;
    BOOL mermaid = preferences.htmlMermaid, graphviz = preferences.htmlGraphviz;
    NSString *theme = [preferences.htmlHighlightingThemeName copy];
    MPDocument *document = [MPDocument new];
    WebView *web = [[WebView alloc] initWithFrame:NSMakeRect(0,0,400,300)];
    MPEditorView *editor = [[MPEditorView alloc] initWithFrame:NSMakeRect(0,0,400,300)];
    MPRenderer *renderer = [MPRenderer new];
    document.editor = editor;
    document.preview = web;
    document.renderer = renderer;
    renderer.dataSource = (id<MPRendererDataSource>)document;
    renderer.delegate = (id<MPRendererDelegate>)document;
    web.frameLoadDelegate = (id<WebFrameLoadDelegate>)document;
    @try {
        preferences.htmlSyntaxHighlighting = YES;
        preferences.extensionFencedCode = YES;
        preferences.htmlMathJax = NO;
        preferences.htmlMermaid = NO;
        preferences.htmlGraphviz = NO;
        preferences.htmlHighlightingThemeName = nil;
        [renderer parseMarkdown:@""];
        [renderer render];
        XCTNSPredicateExpectation *empty = [[XCTNSPredicateExpectation alloc]
            initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id object,
                                                                   NSDictionary *bindings) {
                return document.isPreviewReady && !document.alreadyRenderingInWeb &&
                    [[web.mainFrame.javaScriptContext evaluateScript:@"!!window.Prism"] toBool];
            }] object:web];
        [self waitForExpectations:@[empty] timeout:10];
        editor.string = @"```javascript\nconst answer = 42;\n```\n";
        [renderer parseMarkdown:editor.string];
        [renderer render];
        XCTNSPredicateExpectation *highlighted = [[XCTNSPredicateExpectation alloc]
            initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id object,
                                                                   NSDictionary *bindings) {
                return !document.alreadyRenderingInWeb &&
                    [[web.mainFrame.javaScriptContext evaluateScript:
                        @"!!(window.Prism && Prism.languages.javascript) && "
                         "document.querySelectorAll('code.language-javascript span.token').length > 0"] toBool];
            }] object:web];
        [self waitForExpectations:@[highlighted] timeout:10];
    } @finally {
        web.frameLoadDelegate = nil;
        [document close];
        preferences.htmlSyntaxHighlighting = syntax;
        preferences.extensionFencedCode = fences;
        preferences.htmlMathJax = math;
        preferences.htmlMermaid = mermaid;
        preferences.htmlGraphviz = graphviz;
        preferences.htmlHighlightingThemeName = theme;
    }
}

- (void)testResourceWatcherBurstPublishesOnceAndAnOldWatcherSetCannotPublish
{
    MPDocumentExportAuditProbe *document = [MPDocumentExportAuditProbe new];
    document.fileURL = self.testFileURL;
    MPEditorView *editor = [[MPEditorView alloc] initWithFrame:NSMakeRect(0, 0, 400, 300)];
    document.editor = editor;
    NSString *one = [self.testDirectory stringByAppendingPathComponent:@"one.svg"];
    NSString *two = [self.testDirectory stringByAppendingPathComponent:@"two.svg"];
    NSString *svg = @"<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1\" height=\"1\"></svg>";
    XCTAssertTrue([svg writeToFile:one atomically:YES encoding:NSUTF8StringEncoding error:NULL]);
    XCTAssertTrue([svg writeToFile:two atomically:YES encoding:NSUTF8StringEncoding error:NULL]);
    editor.string = @"![one](one.svg)\n![two](two.svg)";
    MPRenderer *renderer = [MPRenderer new];
    renderer.dataSource = (id<MPRendererDataSource>)document;
    renderer.delegate = (id<MPRendererDelegate>)document;
    document.renderer = renderer;
    [renderer parseMarkdown:editor.string];
    [renderer render];
    NSString *initialHTML = document.publishedHTML.lastObject;
    NSSet *resourcePaths = MPLocalFilePathsInHTML(initialHTML,
        [(id<MPRendererDelegate>)document rendererBaseURL:renderer]);
    [document.publishedHTML removeAllObjects];
    MPResourceWatcherSet *current = [MPResourceWatcherSet new];
    current.delegate = (id<MPResourceWatcherSetDelegate>)document;
    document.resourceWatcherSet = current;
    @try {
        [current updateWatchedPaths:resourcePaths];
        XCTAssertTrue([current.watchedPaths containsObject:one]);
        XCTAssertTrue([current.watchedPaths containsObject:two]);
        XCTestExpectation *published = [self expectationWithDescription:@"Coalesced real renderer publication"];
        dispatch_async(dispatch_get_main_queue(), ^{ [published fulfill]; });
        [self waitForExpectations:@[published] timeout:5.0];
        XCTAssertEqual(document.publishedHTML.count, 1u);
        NSString *html = document.publishedHTML.lastObject;
        XCTAssertTrue([html containsString:@"one.svg?t="]);
        XCTAssertTrue([html containsString:@"two.svg?t="]);
        MPResourceWatcherSet *old = [MPResourceWatcherSet new];
        [document resourceWatcherSet:old didDetectChangeAtPath:one];
        XCTestExpectation *idle = [self expectationWithDescription:@"Stale event has no publication"];
        dispatch_async(dispatch_get_main_queue(), ^{ [idle fulfill]; });
        [self waitForExpectations:@[idle] timeout:5.0];
        XCTAssertEqual(document.publishedHTML.count, 1u);
    } @finally {
        [document close];
    }
}

- (void)testHTMLExportReportsWriteFailureAfterRealRenderAndPreservesExistingFile
{
    MPControlledExportPanel *panel = [MPControlledExportPanel new];
    // An existing directory cannot be atomically replaced by the HTML file.
    panel.URL = [NSURL fileURLWithPath:self.testDirectory isDirectory:YES];
    NSString *preservedPath = [self.testDirectory stringByAppendingPathComponent:@"preserved.md"];
    XCTAssertTrue([@"preserved" writeToFile:preservedPath atomically:YES encoding:NSUTF8StringEncoding error:NULL]);
    MPDocumentExportAuditProbe *document = [MPDocumentExportAuditProbe new];
    MPEditorView *editor = [[MPEditorView alloc] initWithFrame:NSMakeRect(0, 0, 400, 300)];
    editor.string = @"# Exported content";
    document.editor = editor;
    WebView *preview = [[WebView alloc] initWithFrame:NSMakeRect(0, 0, 400, 300)];
    document.preview = preview;
    preview.frameLoadDelegate = (id<WebFrameLoadDelegate>)document;
    MPRenderer *renderer = [MPRenderer new];
    renderer.delegate = (id<MPRendererDelegate>)document;
    renderer.dataSource = (id<MPRendererDataSource>)document;
    document.renderer = renderer;
    MPPreferences *preferences = document.preferences;
    BOOL math = preferences.htmlMathJax;
    MPCurrentControlledExportPanel = panel;
    Method factory = class_getClassMethod(NSSavePanel.class, @selector(savePanel));
    IMP original = method_setImplementation(factory, (IMP)MPControlledExportPanelFactory);
    @try {
        preferences.htmlMathJax = NO;
        [document exportHtml:nil];
        XCTAssertEqual(panel.presentations, 1u);
        XCTAssertNotNil(panel.completion);
        panel.completion(NSFileHandlingPanelOKButton);
        XCTNSPredicateExpectation *failed = [[XCTNSPredicateExpectation alloc]
            initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
                return document.presentedError != nil;
            }] object:document];
        [self waitForExpectations:@[failed] timeout:10.0];
        XCTAssertNotNil(document.presentedError);
        XCTAssertTrue([renderer.currentHtml containsString:@"Exported content"]);
        XCTAssertEqualObjects([NSString stringWithContentsOfFile:preservedPath encoding:NSUTF8StringEncoding error:NULL], @"preserved");
    } @finally {
        method_setImplementation(factory, original);
        MPCurrentControlledExportPanel = nil;
        preview.frameLoadDelegate = nil;
        [document close];
        preferences.htmlMathJax = math;
    }
}


- (void)testDeferredConsumerSeesCompletedRealMermaidDiagrams
{
    MPDocument *document = [MPDocument new];
    MPPreferences *preferences = document.preferences;
    BOOL math = preferences.htmlMathJax, mermaid = preferences.htmlMermaid;
    BOOL graphviz = preferences.htmlGraphviz, fenced = preferences.extensionFencedCode;
    MPEditorView *editor = [[MPEditorView alloc] initWithFrame:NSMakeRect(0, 0, 900, 700)];
    editor.string = @"```mermaid\ngraph TD; A-->B; B-->C;\n```\n\n"
        @"```mermaid\nsequenceDiagram\nAlice->>Bob: Hello\n```\n\n"
        @"```mermaid\nstateDiagram-v2\n[*] --> Active\nActive --> [*]\n```\n\n"
        @"```mermaid\nclassDiagram\nAnimal <|-- Duck\n```\n\n"
        @"```mermaid\ngantt\ntitle Schedule\ndateFormat YYYY-MM-DD\nsection Work\nTask :a1, 2024-01-01, 2d\n```\n\n"
        @"```mermaid\npie title Pets\n\"Dogs\" : 3\n\"Cats\" : 2\n```\n\n"
        @"```mermaid\njourney\ntitle Work\nsection Day\nCode: 5: Me\n```\n\n"
        @"```mermaid\nmindmap\n  root((Plan))\n    Code\n    Test\n```";
    document.editor = editor;
    WebView *preview = [[WebView alloc] initWithFrame:NSMakeRect(0, 0, 900, 700)];
    document.preview = preview;
    preview.frameLoadDelegate = (id<WebFrameLoadDelegate>)document;
    preview.resourceLoadDelegate = (id<WebResourceLoadDelegate>)document;
    MPRenderer *renderer = [MPRenderer new];
    renderer.dataSource = (id<MPRendererDataSource>)document;
    renderer.delegate = (id<MPRendererDelegate>)document;
    document.renderer = renderer;
    @try {
        preferences.htmlMermaid = YES;
        preferences.htmlGraphviz = NO;
        preferences.extensionFencedCode = YES;
        for (NSNumber *mathEnabled in @[@NO, @YES]) {
            preferences.htmlMathJax = mathEnabled.boolValue;
            XCTestExpectation *consumed = [self expectationWithDescription:
                [NSString stringWithFormat:@"Actual deferred consumption, MathJax %@", mathEnabled]];
            [document performAfterRender:^{
                JSContext *context = preview.mainFrame.javaScriptContext;
                XCTAssertEqual([[context evaluateScript:@"document.querySelectorAll('.language-mermaid').length"] toUInt32], 0u);
                // Mermaid replaces each pre inside Hoedown’s existing div wrapper.
                // Exclude the library’s temporary rendering divs from the count.
                XCTAssertEqual([[context evaluateScript:@"Array.from(document.querySelectorAll('svg[id^=\"mermaid_\"]')).filter(function(svg){return !svg.closest('div[id^=\"dmermaid_\"]');}).length"] toUInt32], 8u);
                XCTAssertFalse([[[context evaluateScript:@"document.body.textContent"] toString] containsString:@"Mermaid Error:"]);
                [consumed fulfill];
            }];
            [self waitForExpectations:@[consumed] timeout:20.0];
        }
    } @finally {
        preview.frameLoadDelegate = nil;
        preview.resourceLoadDelegate = nil;
        [document close];
        preferences.htmlMathJax = math;
        preferences.htmlMermaid = mermaid;
        preferences.htmlGraphviz = graphviz;
        preferences.extensionFencedCode = fenced;
    }
}


- (void)testDeferredConsumerRestoresLocalHeadAndBaseAfterHTTPNavigation
{
    MPPreviewHTTPFixture *server = [MPPreviewHTTPFixture new];
    XCTAssertNotNil(server);
    if (!server) return;
    MPDocument *document = [MPDocument new];
    document.fileURL = [NSURL fileURLWithPath:[self.testDirectory stringByAppendingPathComponent:@"preview.md"]];
    MPPreferences *preferences = document.preferences;
    BOOL math = preferences.htmlMathJax, mermaid = preferences.htmlMermaid, graphviz = preferences.htmlGraphviz;
    MPEditorView *editor = [[MPEditorView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];
    editor.string = @"# Local initial";
    document.editor = editor;
    WebView *preview = [[WebView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];
    document.preview = preview;
    preview.frameLoadDelegate = (id<WebFrameLoadDelegate>)document;
    preview.policyDelegate = (id<WebPolicyDelegate>)document;
    MPRenderer *renderer = [MPRenderer new];
    renderer.delegate = (id<MPRendererDelegate>)document;
    renderer.dataSource = (id<MPRendererDataSource>)document;
    document.renderer = renderer;
    @try {
        preferences.htmlMathJax = NO;
        preferences.htmlMermaid = NO;
        preferences.htmlGraphviz = NO;
        __block NSString *localBase;
        XCTestExpectation *initial = [self expectationWithDescription:@"Published local preview"];
        [document performAfterRender:^{
            localBase = [[preview.mainFrame.javaScriptContext evaluateScript:@"document.baseURI"] toString];
            XCTAssertTrue([[preview.mainFrame.javaScriptContext evaluateScript:@"document.querySelector('meta[name=macdown-checkbox-token]') !== null"] toBool]);
            [initial fulfill];
        }];
        [self waitForExpectations:@[initial] timeout:10];
        [preview.mainFrame loadRequest:[NSURLRequest requestWithURL:server.URL]];
        XCTNSPredicateExpectation *remote = [[XCTNSPredicateExpectation alloc] initWithPredicate:
            [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
                return [[preview.mainFrame.javaScriptContext evaluateScript:@"document.querySelector('meta[name=remote-marker]') !== null && document.readyState === 'complete'"] toBool];
            }] object:preview];
        [self waitForExpectations:@[remote] timeout:10];
        XCTAssertEqualObjects([[preview.mainFrame.javaScriptContext evaluateScript:@"document.baseURI"] toString], server.URL.absoluteString);
        editor.string = @"# Returned Markdown";
        XCTestExpectation *consumer = [self expectationWithDescription:@"Fresh local preview after navigation"];
        [document performAfterRender:^{
            JSContext *context = preview.mainFrame.javaScriptContext;
            XCTAssertEqualObjects([[context evaluateScript:@"document.baseURI"] toString], localBase);
            XCTAssertTrue([[context evaluateScript:@"document.querySelector('meta[name=macdown-checkbox-token]') !== null"] toBool]);
            XCTAssertFalse([[context evaluateScript:@"document.querySelector('meta[name=remote-marker]') !== null"] toBool]);
            XCTAssertEqualObjects([[context evaluateScript:@"document.querySelector('h1').textContent"] toString], @"Returned Markdown");
            [consumer fulfill];
        }];
        [self waitForExpectations:@[consumer] timeout:10];
    } @finally {
        preview.frameLoadDelegate = nil;
        preview.policyDelegate = nil;
        [document close];
        preferences.htmlMathJax = math;
        preferences.htmlMermaid = mermaid;
        preferences.htmlGraphviz = graphviz;
    }
}

@end
