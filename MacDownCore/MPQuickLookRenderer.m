//
//  MPQuickLookRenderer.m
//  MacDownCore
//
//  Quick Look renderer facade for MacDown 3000 (Issue #284)
//  Copyright (c) 2025 Tzu-ping Chung. All rights reserved.
//

#import "MPQuickLookRenderer.h"
#import "MPQuickLookPreferences.h"
#import <hoedown/html.h>
#import <hoedown/document.h>
#import <hoedown/escape.h>
#import "../MacDown/Code/Extension/hoedown_html_patch.h"
#import "MPMarkdownPreprocessor.h"

// Error domain for Quick Look renderer
NSString * const MPQuickLookRendererErrorDomain = @"MPQuickLookRendererErrorDomain";

// Constants
static NSString * const kMPPrismThemeDirectory = @"Prism/themes";




#pragma mark - Private Helper Functions

/**
 * Get the bundle containing Quick Look resources.
 * This could be the main app bundle or the framework bundle.
 */
NS_INLINE NSBundle *MPQuickLookBundle(void)
{
    // Try framework bundle first (when running as part of MacDownCore.framework)
    NSBundle *bundle = [NSBundle bundleForClass:[MPQuickLookRenderer class]];

    // Fall back to main bundle
    if (!bundle) {
        bundle = [NSBundle mainBundle];
    }

    return bundle;
}

/**
 * Read file contents as a string.
 */
NS_INLINE NSString *MPReadFileContents(NSString *path)
{
    if (!path) return nil;

    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error];
    if (error) {
        NSLog(@"[MPQuickLookRenderer] Failed to read file %@: %@", path, error);
        return nil;
    }
    return content;
}

/**
 * Get the path to a CSS style file.
 */
NS_INLINE NSString *MPStylePathForName(NSString *name)
{
    if (!name) return nil;

    // Add .css extension if not present
    if (![[name pathExtension] isEqualToString:@"css"]) {
        name = [name stringByAppendingPathExtension:@"css"];
    }

    NSFileManager *manager = [NSFileManager defaultManager];

    // Look in Application Support first (user styles)
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
        NSApplicationSupportDirectory, NSUserDomainMask, YES);
    if (paths.count > 0) {
        NSString *appSupportPath = [paths[0] stringByAppendingPathComponent:@"MacDown 3000/Styles"];
        NSString *stylePath = [appSupportPath stringByAppendingPathComponent:name];
        if ([manager fileExistsAtPath:stylePath]) {
            return stylePath;
        }
    }

    // Fall back to bundle resources. Try the bundle that defines this class
    // first -- the real answer in the shipped MacDownCore.framework / QuickLook
    // extension -- then mainBundle as an additional fallback. This file is also
    // compiled directly into the MacDownTests host (see MacDownTests target
    // Sources), so -bundleForClass: can resolve to that host's own image there,
    // which carries no Styles/ resources; mainBundle in that case is the actual
    // test host app, which does.
    for (NSBundle *bundle in @[MPQuickLookBundle(), [NSBundle mainBundle]]) {
        NSString *resourcePath = bundle.resourcePath;
        if (!resourcePath) continue;
        NSString *bundlePath =
            [NSString pathWithComponents:@[resourcePath, @"Styles", name]];
        if ([manager fileExistsAtPath:bundlePath]) {
            return bundlePath;
        }
    }

    return nil;
}

/**
 * Get URL for Prism highlighting theme.
 * Checks Application Support directory first (user themes),
 * then falls back to bundle resources.
 */
NS_INLINE NSURL *MPHighlightingThemeURLForName(NSString *name)
{
    NSString *themeName = [NSString stringWithFormat:@"prism-%@", [name lowercaseString]];
    if ([[themeName pathExtension] isEqualToString:@"css"]) {
        themeName = [themeName stringByDeletingPathExtension];
    }
    NSString *fileName = [themeName stringByAppendingPathExtension:@"css"];

    NSFileManager *manager = [NSFileManager defaultManager];

    // Check Application Support first (user themes)
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
        NSApplicationSupportDirectory, NSUserDomainMask, YES);
    if (paths.count > 0) {
        NSString *userThemePath = [paths[0]
            stringByAppendingPathComponent:
                [@"MacDown 3000" stringByAppendingPathComponent:
                    [kMPPrismThemeDirectory stringByAppendingPathComponent:
                        fileName]]];
        if ([manager fileExistsAtPath:userThemePath]) {
            return [NSURL fileURLWithPath:userThemePath];
        }
    }

    // Fall back to bundle resources
    NSBundle *bundle = MPQuickLookBundle();
    NSURL *url = [bundle URLForResource:themeName
                          withExtension:@"css"
                           subdirectory:kMPPrismThemeDirectory];

    // Fallback to default theme
    if (!url) {
        url = [bundle URLForResource:@"prism"
                       withExtension:@"css"
                        subdirectory:kMPPrismThemeDirectory];
    }

    return url;
}

NS_INLINE NSString *MPQuickLookContentSecurityPolicy(void)
{
    return @"default-src 'none'; "
           @"base-uri 'none'; "
           @"form-action 'none'; "
           @"object-src 'none'; "
           @"frame-src 'none'; "
           @"connect-src 'none'; "
           @"img-src data: file:; "
           @"media-src data: file:; "
           @"font-src data: file:; "
           @"style-src 'unsafe-inline'; "
           @"script-src 'none'";
}


@interface MPQuickLookRenderer ()
@property (nonatomic, strong) MPQuickLookPreferences *preferences;
@end


@implementation MPQuickLookRenderer

- (instancetype)init
{
    self = [super init];
    if (self) {
        _preferences = [MPQuickLookPreferences sharedPreferences];
    }
    return self;
}

#pragma mark - Public Methods

- (NSString *)renderMarkdown:(NSString *)markdown
{
    if (!markdown) {
        return nil;
    }

    if (markdown.length == 0) {
        return [self wrapBodyInHTML:@""];
    }

    // Preprocess markdown
    NSDictionary *preprocessed = MPPreprocessMarkdown(markdown, ([self.preferences extensionFlags] & HOEDOWN_EXT_FENCED_CODE) != 0, 0);

    // Parse markdown to HTML body
    NSString *body = [self parseMarkdownToHTML:preprocessed[@"text"] codeEscapeToken:preprocessed[@"codeEscapeToken"] taskPrefix:preprocessed[@"taskPrefix"]];

    // Wrap in complete HTML document
    return [self wrapBodyInHTML:body];
}

- (NSString *)renderMarkdownFromURL:(NSURL *)url error:(NSError **)error
{
    if (!url) {
        if (error) {
            *error = [NSError errorWithDomain:MPQuickLookRendererErrorDomain
                                         code:1
                                     userInfo:@{NSLocalizedDescriptionKey: @"URL is nil"}];
        }
        return nil;
    }

    NSError *readError = nil;
    NSString *markdown = [NSString stringWithContentsOfURL:url
                                                  encoding:NSUTF8StringEncoding
                                                     error:&readError];

    // Fall back to auto-detected encoding if UTF-8 fails (e.g. UTF-16 with BOM)
    if (!markdown) {
        readError = nil;
        markdown = [NSString stringWithContentsOfURL:url
                                        usedEncoding:NULL
                                               error:&readError];
    }

    // Last resort: ISO Latin-1 can decode any byte sequence, so it never fails.
    // This handles single-byte encodings that lack a BOM for auto-detection.
    if (!markdown) {
        readError = nil;
        markdown = [NSString stringWithContentsOfURL:url
                                            encoding:NSISOLatin1StringEncoding
                                               error:&readError];
    }

    if (!markdown) {
        if (error) {
            *error = readError;
        }
        return nil;
    }

    // Normalize Windows CRLF to LF (Issue #382)
    markdown = [markdown stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];

    return [self renderMarkdown:markdown];
}

#pragma mark - Private Methods

- (NSString *)parseMarkdownToHTML:(NSString *)markdown codeEscapeToken:(NSString *)codeEscapeToken taskPrefix:(NSString *)taskPrefix
{
    int extensions = [self.preferences extensionFlags];
    int flags = [self.preferences rendererFlags];

    // Create HTML renderer
    hoedown_renderer *renderer = hoedown_html_renderer_new(flags, 0);

    // Preserve Prism language classes, but Quick Look never executes Prism JS.
    hoedown_html_renderer_state_extra extra = {0};
    __attribute__((objc_precise_lifetime)) NSDictionary *context = @{@"headingSlugs": [NSMutableDictionary dictionary]};
    extra.owner = (__bridge void *)context;
    extra.heading_slug = MPUniqueHeadingSlug;
    extra.code_escape_token = codeEscapeToken.UTF8String;
    extra.task_marker_prefix = taskPrefix.UTF8String;
    ((hoedown_html_renderer_state *)renderer->opaque)->opaque = &extra;
    renderer->blockcode = hoedown_patch_render_blockcode;
    renderer->header = hoedown_patch_render_header;
    renderer->listitem = hoedown_patch_render_listitem;
    renderer->table_header = hoedown_patch_render_table_header;

    // Create document
    hoedown_document *document = hoedown_document_new(
        renderer, extensions, MPMarkdownMaximumNesting);

    // Render
    NSData *inputData = [markdown dataUsingEncoding:NSUTF8StringEncoding];
    hoedown_buffer *ob = hoedown_buffer_new(64);
    hoedown_document_render(document, ob, inputData.bytes, inputData.length);

    NSString *result = @"";
    if (ob->size > 0) {
        result = [[NSString alloc] initWithBytes:ob->data
                                          length:ob->size
                                        encoding:NSUTF8StringEncoding];
    }

    // Cleanup
    hoedown_buffer_free(ob);
    hoedown_document_free(document);
    hoedown_html_renderer_free(renderer);

    return MPRemoveTaskMarkers(result ?: @"", taskPrefix);
}

- (NSString *)wrapBodyInHTML:(NSString *)body
{
    NSMutableString *html = [NSMutableString string];

    // HTML header
    [html appendString:@"<!DOCTYPE html>\n"];
    [html appendString:@"<html>\n<head>\n"];
    [html appendString:@"<meta charset=\"utf-8\">\n"];
    [html appendString:@"<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n"];
    [html appendFormat:@"<meta http-equiv=\"Content-Security-Policy\" content=\"%@\">\n",
                       MPQuickLookContentSecurityPolicy()];

    // Embed CSS styles
    [html appendString:[self embeddedStyles]];

    [html appendString:@"</head>\n<body>\n"];

    // Body content
    [html appendString:body ?: @""];

    [html appendString:@"\n</body>\n</html>"];

    return html;
}

- (NSString *)embeddedStyles
{
    NSMutableString *styles = [NSMutableString string];

    // Main CSS style
    NSString *styleName = [self.preferences styleName];
    NSString *stylePath = MPStylePathForName(styleName);
    NSString *styleContent = MPReadFileContents(stylePath);

    if (styleContent.length > 0) {
        [styles appendString:@"<style type=\"text/css\">\n"];
        [styles appendString:styleContent];
        [styles appendString:@"\n</style>\n"];
    }

    // Prism theme CSS (if syntax highlighting enabled)
    if ([self.preferences syntaxHighlightingEnabled]) {
        NSString *themeName = [self.preferences highlightingThemeName];
        NSURL *themeURL = MPHighlightingThemeURLForName(themeName);
        NSString *themeContent = MPReadFileContents(themeURL.path);

        if (themeContent.length > 0) {
            [styles appendString:@"<style type=\"text/css\">\n"];
            [styles appendString:themeContent];
            [styles appendString:@"\n</style>\n"];
        }
    }

    return styles;
}
@end
