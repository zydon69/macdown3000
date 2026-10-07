// Exercise deferred geometry with a real NSTextView/layout manager/main queue.
// Preferences are process-local memory: no application or global domain writes.
#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import "MPEditorView.h"

@interface MPGeometryMemoryDefaults : NSUserDefaults
@property (nonatomic, strong) NSMutableDictionary *values;
@end

@implementation MPGeometryMemoryDefaults
- (id)objectForKey:(NSString *)key { return self.values[key]; }
- (void)setObject:(id)value forKey:(NSString *)key
{
    if (value) self.values[key] = value;
    else [self.values removeObjectForKey:key];
}
- (void)setBool:(BOOL)value forKey:(NSString *)key
{
    [self setObject:@(value) forKey:key];
}
- (BOOL)boolForKey:(NSString *)key { return [[self objectForKey:key] boolValue]; }
- (void)setInteger:(NSInteger)value forKey:(NSString *)key
{
    [self setObject:@(value) forKey:key];
}
- (NSInteger)integerForKey:(NSString *)key
{
    return [[self objectForKey:key] integerValue];
}
@end

static MPGeometryMemoryDefaults *memoryDefaults;
static id MPGeometryStandardDefaults(id receiver, SEL selector)
{
    return memoryDefaults;
}

static MPEditorView *MPGeometryView(void)
{
    MPEditorView *view = [[MPEditorView alloc] initWithFrame:NSMakeRect(0, 0, 300, 200)];
    view.string = @"hello\nworld";
    [view.layoutManager ensureLayoutForTextContainer:view.textContainer];
    return view;
}

int main(void)
{
    @autoreleasepool
    {
        memoryDefaults = [MPGeometryMemoryDefaults new];
        memoryDefaults.values = [NSMutableDictionary dictionary];
        Method defaultsMethod = class_getClassMethod(NSUserDefaults.class,
                                                       @selector(standardUserDefaults));
        method_setImplementation(defaultsMethod, (IMP)MPGeometryStandardDefaults);
        [NSApplication sharedApplication];

        MPEditorView *toggledView = MPGeometryView();
        toggledView.scrollsPastEnd = YES;
        toggledView.scrollsPastEnd = NO;

        MPEditorView *changedView = MPGeometryView();
        changedView.scrollsPastEnd = YES;
        changedView.string = @"updated text\nwith another line\nand a third line";
        [changedView.layoutManager ensureLayoutForTextContainer:changedView.textContainer];
        changedView.scrollsPastEnd = NO;

        MPEditorView *enabledView = MPGeometryView();
        enabledView.scrollsPastEnd = YES;
        enabledView.scrollsPastEnd = NO;
        enabledView.scrollsPastEnd = YES;

        NSBlockOperation *verify = [NSBlockOperation blockOperationWithBlock:^{
            for (MPEditorView *disabledView in @[toggledView, changedView])
            {
                if (!NSEqualRects(disabledView.contentRect, disabledView.frame))
                {
                    fprintf(stderr, "FAIL disabled contentRect=%s frame=%s\n",
                            NSStringFromRect(disabledView.contentRect).UTF8String,
                            NSStringFromRect(disabledView.frame).UTF8String);
                    exit(1);
                }
            }
            if (!enabledView.scrollsPastEnd ||
                NSEqualRects(enabledView.contentRect, enabledView.frame) ||
                enabledView.contentRect.size.height <= 0)
            {
                fprintf(stderr, "FAIL enabled geometry was not updated\n");
                exit(1);
            }
            puts("PASS deferred enable, text change, disable and re-enable geometry");
            exit(0);
        }];
        // Drain precisely the queued production operations, then consume their
        // public result. No timer-dependent assertion or replacement layout.
        for (NSOperation *operation in NSOperationQueue.mainQueue.operations)
            [verify addDependency:operation];
        [NSOperationQueue.mainQueue addOperation:verify];
        dispatch_main();
    }
}
