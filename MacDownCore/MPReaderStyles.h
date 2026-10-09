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

// A task's checkbox replaces its list marker; ordinary nested lists retain
// their own markers. Keep this structural rule shared by preview and exports.
NS_INLINE NSString *MPTaskListStyleTag(void)
{
    return @"<style id=\"macdown-task-list-markers\">"
        "li.task-list-item{list-style-type:none!important;}"
        "</style>";
}
