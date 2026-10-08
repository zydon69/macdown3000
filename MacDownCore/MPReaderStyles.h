// Shared reader presentation; does not alter Markdown or copied code.
#import <Foundation/Foundation.h>
NS_INLINE NSString *MPCodeWrappingStyleTag(void)
{
    return @"<style id=\"macdown-code-wrapping\">@media screen {"
        "pre, pre code, pre code[class*=\"language-\"] {"
        "white-space:pre-wrap !important;overflow-wrap:anywhere;word-break:normal;}"
        "pre {max-width:100%;box-sizing:border-box;}"
        "}</style>";
}
