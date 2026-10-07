// Shared Markdown compatibility rules for the application and Quick Look.
#import <Foundation/Foundation.h>
#import <hoedown/buffer.h>

// Both HTML and TOC renderers reserve final ids in document order. Keep the
// registry local to one parse, including naturally suffixed headings.
NS_INLINE hoedown_buffer *MPUniqueHeadingSlug(const hoedown_buffer *slug, void *owner)
{
    NSDictionary *context = (__bridge NSDictionary *)owner;
    NSMutableDictionary<NSString *, NSNumber *> *used = context[@"headingSlugs"];
    NSString *base = [[NSString alloc] initWithBytes:slug->data length:slug->size encoding:NSUTF8StringEncoding];
    if (!used || !base) return NULL;
    NSString *candidate = base;
    NSUInteger suffix = used[base].unsignedIntegerValue;
    while (used[candidate]) {
        candidate = [NSString stringWithFormat:@"%@-%lu", base, (unsigned long)++suffix];
    }
    used[base] = @(suffix);
    used[candidate] = @0;
    NSData *bytes = [candidate dataUsingEncoding:NSUTF8StringEncoding];
    hoedown_buffer *result = hoedown_buffer_new(MAX((size_t)1, bytes.length));
    hoedown_buffer_put(result, bytes.bytes, bytes.length);
    return result;
}

// Bound recursive Markdown nesting for interactive previews and Quick Look.
static const size_t MPMarkdownMaximumNesting = 128;

// Compatibility substitutions must never change literal inline or indented
// code. Hoedown closes a code span at the next run containing its opener's
// number of backticks; use that same boundary before applying prose rules.
NS_INLINE NSArray<NSValue *> *MPMarkdownLiteralRanges(NSString *text)
{
    NSMutableArray *ranges = [NSMutableArray array];
    for (NSUInteger i = 0; i < text.length; i++) {
        if ([text characterAtIndex:i] != '`') continue;
        NSUInteger backslashes = 0;
        while (i > backslashes && [text characterAtIndex:i - backslashes - 1] == '\\') backslashes++;
        if (backslashes % 2) continue;
        NSUInteger width = 1;
        while (i + width < text.length && [text characterAtIndex:i + width] == '`') width++;
        NSString *delimiter = [text substringWithRange:NSMakeRange(i, width)];
        NSRange close = [text rangeOfString:delimiter options:0
            range:NSMakeRange(i + width, text.length - i - width)];
        if (close.location != NSNotFound) {
            [ranges addObject:[NSValue valueWithRange:NSMakeRange(i, NSMaxRange(close) - i)]];
            i = NSMaxRange(close) - 1;
        } else i += width - 1;
    }
    NSRegularExpression *indented = [NSRegularExpression regularExpressionWithPattern:
        @"^(?:\\t| {4}).*" options:NSRegularExpressionAnchorsMatchLines error:NULL];
    for (NSTextCheckingResult *match in [indented matchesInString:text options:0 range:NSMakeRange(0, text.length)])
        [ranges addObject:[NSValue valueWithRange:match.range]];
    return ranges;
}

NS_INLINE NSString *MPReplaceMarkdownProse(NSString *text, NSRegularExpression *expression, NSString *replacement)
{
    NSArray<NSValue *> *literals = MPMarkdownLiteralRanges(text);
    NSMutableString *result = [text mutableCopy];
    NSArray *matches = [expression matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    for (NSTextCheckingResult *match in matches.reverseObjectEnumerator) {
        BOOL literal = NO;
        for (NSValue *value in literals) {
            if (NSIntersectionRange(match.range, value.rangeValue).length) { literal = YES; break; }
        }
        if (!literal) [result replaceCharactersInRange:match.range withString:
            [expression replacementStringForResult:match inString:text offset:0 template:replacement]];
    }
    return result;
}

NS_INLINE NSString *MPPreprocessProse(NSString *text)
{
    static NSRegularExpression *lists, *shortcuts;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        lists = [NSRegularExpression regularExpressionWithPattern:
            @"^(?![ \\t]*[-*+][ \\t])(?![ \\t]*\\d+\\.[ \\t])(.+)\\n([-*+]|\\d+\\.)[ \\t]"
            options:NSRegularExpressionAnchorsMatchLines error:NULL];
        shortcuts = [NSRegularExpression regularExpressionWithPattern:
            @"(?<!\\])\\[([^\\]]+)\\](\\s+)(?=\\[)" options:0 error:NULL];
    });
    text = MPReplaceMarkdownProse(text, lists, @"$1\n\n$2 ");
    return MPReplaceMarkdownProse(text, shortcuts, @"[$1][]$2");
}

NS_INLINE NSUInteger MPMarkdownQuoteDepth(NSString *line, NSUInteger *contentStart)
{
    NSUInteger offset = 0, depth = 0;
    while (offset < line.length) {
        NSUInteger prefix = offset;
        for (NSUInteger spaces = 0; spaces < 3 && offset < line.length && [line characterAtIndex:offset] == ' '; spaces++) offset++;
        if (offset >= line.length || [line characterAtIndex:offset] != '>') {
            offset = prefix;
            break;
        }
        offset++; depth++;
        if (offset < line.length && [line characterAtIndex:offset] == ' ') offset++;
    }
    if (contentStart) *contentStart = offset;
    return depth;
}

// Hoedown extracts reference definitions before parsing fenced code. Protect
// only those definitions with a per-parse marker, removed by the blockcode
// callback before escaping. Unlike a zero-width character, this cannot alter
// copied code or remove a character already present in the source.
NS_INLINE NSDictionary<NSString *, NSString *> *MPPreprocessMarkdown(NSString *text, BOOL fencedCodeEnabled, NSUInteger sourceOffset)
{
    text = text ?: @"";
    NSString *taskPrefix;
    do { taskPrefix = [NSString stringWithFormat:@"macdown-task-%@Z", NSUUID.UUID.UUIDString]; }
    while ([text containsString:taskPrefix]);
    NSRegularExpression *tasks = [NSRegularExpression regularExpressionWithPattern:
        @"^[ \t]*(?:>[ \t]*)*(?:[-*+]|\\d+[.)])[ \t]+\\[([ xX])\\]"
        options:NSRegularExpressionAnchorsMatchLines error:NULL];
    NSMutableString *marked = [text mutableCopy];
    NSArray *matches = [tasks matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    for (NSTextCheckingResult *match in matches.reverseObjectEnumerator) {
        NSUInteger offset = sourceOffset + [match rangeAtIndex:1].location;
        [marked insertString:[NSString stringWithFormat:@"%@%luZ", taskPrefix, (unsigned long)offset]
                     atIndex:NSMaxRange(match.range)];
    }
    text = [marked stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    if (!fencedCodeEnabled) return @{@"text": MPPreprocessProse(text), @"codeEscapeToken": @"", @"taskPrefix": taskPrefix};
    NSString *marker;
    do { marker = [NSString stringWithFormat:@"macdown-code-%@", NSUUID.UUID.UUIDString]; }
    while ([text containsString:marker]);
    static NSRegularExpression *fencePattern;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        fencePattern = [NSRegularExpression regularExpressionWithPattern:
            @"^[ \\t]*(?:>[ \\t]*)*(?:(?:[-*+]|\\d+[.)])[ \\t]+)?(`{3,}|~{3,})(.*)$" options:0 error:NULL];
    });
    NSMutableString *result = [NSMutableString string];
    NSMutableString *prose = [NSMutableString string];
    NSString *fence = nil;
    NSUInteger fenceQuoteDepth = 0;
    NSUInteger fenceIndent = 0;
    BOOL fenceInList = NO;
    BOOL listContext = NO;
    NSRegularExpression *listPattern = [NSRegularExpression regularExpressionWithPattern:
        @"^[ \\t]*(?:>[ \\t]*)*(?:[-*+]|\\d+[.)])[ \\t]+" options:0 error:NULL];
    NSArray<NSString *> *lines = [text componentsSeparatedByString:@"\n"];
    for (NSUInteger index = 0; index < lines.count; index++) {
        NSString *line = lines[index];
        BOOL newline = index + 1 < lines.count;
        NSUInteger contentStart = 0;
        NSUInteger quoteDepth = MPMarkdownQuoteDepth(line, &contentStart);
        BOOL blank = ![[line substringFromIndex:contentStart]
            stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet].length;
        if (fence && blank && newline) {
            NSString *next = lines[index + 1];
            NSUInteger nextStart = 0;
            NSUInteger nextDepth = MPMarkdownQuoteDepth(next, &nextStart);
            BOOL nextBlank = ![[next substringFromIndex:nextStart]
                stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet].length;
            BOOL quoteEnded = fenceQuoteDepth && quoteDepth < fenceQuoteDepth && nextDepth < fenceQuoteDepth && !nextBlank;
            BOOL listEnded = fenceInList && next.length && [next characterAtIndex:0] != ' ' && [next characterAtIndex:0] != '\t';
            if (quoteEnded || listEnded) {
                // Hoedown closes the enclosing container here even when its
                // code fence was never explicitly closed.
                fence = nil;
                listContext = NO;
            }
        }
        NSTextCheckingResult *match = [fencePattern firstMatchInString:line options:0
            range:NSMakeRange(0, line.length)];
        NSString *candidate = match ? [line substringWithRange:[match rangeAtIndex:1]] : nil;
        NSString *suffix = match ? [line substringWithRange:[match rangeAtIndex:2]] : nil;
        BOOL listLine = [listPattern firstMatchInString:line options:0 range:NSMakeRange(0, line.length)] != nil;
        if (listLine) listContext = YES;
        BOOL unindented = line.length && [line characterAtIndex:0] != ' ' && [line characterAtIndex:0] != '\t';
        BOOL containerFence = match && ([match rangeAtIndex:1].location <= 3 ||
            [[line substringToIndex:[match rangeAtIndex:1].location] containsString:@">"] || listContext);
        if (!fence && !listLine && unindented && !candidate) listContext = NO;
        if (!fence && candidate && containerFence &&
            ![suffix containsString:[candidate substringToIndex:3]]) {
            [result appendString:MPPreprocessProse(prose)];
            if (prose.length && ![prose hasSuffix:@"\n\n"]) [result appendString:@"\n"];
            [prose setString:@""];
            fence = candidate;
            fenceQuoteDepth = quoteDepth;
            fenceInList = listContext && (listLine ||
                ([match rangeAtIndex:1].location > 0 && !quoteDepth));
            NSUInteger column = [match rangeAtIndex:1].location - contentStart;
            fenceIndent = fenceInList ? (listLine ? 0 : (column > 4 ? column - 4 : 0)) : column;
            [result appendString:line];
        } else if (fence) {
            NSUInteger column = match ? [match rangeAtIndex:1].location - contentStart : NSNotFound;
            NSUInteger indent = fenceInList && column != NSNotFound ? (column > 4 ? column - 4 : 0) : column;
            if ([candidate isEqualToString:fence] && indent == fenceIndent &&
                ![suffix stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet].length) {
                fence = nil;
                [result appendString:line];
            } else {
                NSString *protected = [line stringByReplacingOccurrencesOfString:@"]:"
                    withString:[NSString stringWithFormat:@"]%@:", marker]];
                [result appendString:protected];
            }
        } else {
            [prose appendString:line];
            if (newline) [prose appendString:@"\n"];
            continue;
        }
        if (newline) [result appendString:@"\n"];
    }
    [result appendString:MPPreprocessProse(prose)];
    return @{@"text": result, @"codeEscapeToken": marker, @"taskPrefix": taskPrefix};
}

NS_INLINE NSString *MPRemoveTaskMarkers(NSString *html, NSString *taskPrefix)
{
    if (!taskPrefix.length) return html;
    NSRegularExpression *markers = [NSRegularExpression regularExpressionWithPattern:
        [[NSRegularExpression escapedPatternForString:taskPrefix] stringByAppendingString:@"[0-9]+Z"]
        options:0 error:NULL];
    return [markers stringByReplacingMatchesInString:html options:0
        range:NSMakeRange(0, html.length) withTemplate:@""];
}
