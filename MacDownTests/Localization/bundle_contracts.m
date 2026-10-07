// Run against a built .app, so missing Xcode resource registration fails even
// when the repository translation files themselves are complete.
#import <Foundation/Foundation.h>
#import "JJPluralForm.h"

int main(int argc, const char *argv[])
{
    @autoreleasepool {
        if (argc != 2) return 2;
        NSBundle *app = [NSBundle bundleWithPath:@(argv[1])];
        if (!app.resourcePath) return 2;
        NSDictionary *cases = @{
            @"da": @[@"Indstillinger", @"1 ord", @"2 ord", @"5 ord"],
            @"fi": @[@"Asetukset", @"1 sana", @"2 sanaa", @"5 sanaa"],
            @"he": @[@"העדפות", @"1 מילה", @"2 מילים", @"5 מילים"],
            @"hi": @[@"प्राथमिकताएं", @"1 शब्द", @"2 शब्द", @"5 शब्द"],
            @"uk": @[@"Налаштування", @"1 слово", @"2 слова", @"5 слів"]
        };
        for (NSString *locale in cases) {
            NSString *path = [app.resourcePath stringByAppendingPathComponent:
                              [locale stringByAppendingPathExtension:@"lproj"]];
            NSBundle *localized = [NSBundle bundleWithPath:path];
            NSString *title = [localized localizedStringForKey:@"Preferences" value:@"MISSING" table:nil];
            NSArray *expected = cases[locale];
            if (![title isEqual:expected[0]]) {
                fprintf(stderr, "FAIL %s Preferences: %s\n", locale.UTF8String, title.UTF8String);
                return 1;
            }
            NSString *rule = [localized localizedStringForKey:@"JJ_PLURAL_FORM_RULE" value:@"MISSING" table:nil];
            NSString *forms = [localized localizedStringForKey:@"WORDS_PLURAL_STRING" value:@"MISSING" table:nil];
            if ([rule isEqual:@"MISSING"] || [forms isEqual:@"MISSING"]) return 1;
            NSArray *numbers = @[@1, @2, @5];
            for (NSUInteger i = 0; i < numbers.count; i++) {
                NSString *value = [JJPluralForm pluralStringForNumber:[numbers[i] unsignedIntegerValue]
                    withPluralForms:forms usingPluralRule:(JJPluralRule)rule.integerValue localizeNumeral:NO];
                if (![value isEqual:expected[i+1]]) {
                    fprintf(stderr, "FAIL %s plural: %s\n", locale.UTF8String, value.UTF8String);
                    return 1;
                }
            }
            fprintf(stdout, "PASS bundled %s title and 1/2/5 words consumed\n", locale.UTF8String);
        }
        return 0;
    }
}
