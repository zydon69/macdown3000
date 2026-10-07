#import <Cocoa/Cocoa.h>
#import "../../MacDown/Code/Extension/NSTextView+Autocomplete.h"

static BOOL check(NSString *input, NSRange range, NSString *padding,
                  NSString *expected, NSRange expectedRange)
{
    NSTextView *view = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 500, 300)];
    view.string = input;
    view.selectedRange = range;
    [view indentSelectedLinesWithPadding:padding];
    BOOL success = [view.string isEqual:expected] && NSEqualRanges(view.selectedRange, expectedRange);
    if (success) {
        [view unindentSelectedLines];
        success = [view.string isEqual:input] && NSEqualRanges(view.selectedRange, range);
    }
    fprintf(success ? stdout : stderr, "%s indent/unindent selection: %s range=%s\n",
        success ? "PASS" : "FAIL", view.string.UTF8String, NSStringFromRange(view.selectedRange).UTF8String);
    return success;
}

int main(void)
{
    @autoreleasepool {
        [NSApplication sharedApplication];
        BOOL success = check(@"a\n\nb", NSMakeRange(0, 4), @"    ", @"    a\n    \n    b", NSMakeRange(4, 12));
        success &= check(@"a\n\nb\n", NSMakeRange(0, 5), @"\t", @"\ta\n\t\n\tb\n", NSMakeRange(1, 7));
        success &= check(@"\n\nx", NSMakeRange(0, 3), @"    ", @"    \n    \n    x", NSMakeRange(4, 11));
        success &= check(@"ab\n\ncd", NSMakeRange(1, 4), @"    ", @"    ab\n    \n    cd", NSMakeRange(5, 12));
        success &= check(@"a\n\nb", NSMakeRange(2, 0), @"    ", @"a\n    \nb", NSMakeRange(6, 0));
        success &= check(@"", NSMakeRange(0, 0), @"    ", @"", NSMakeRange(0, 0));
        return success ? 0 : 1;
    }
}
