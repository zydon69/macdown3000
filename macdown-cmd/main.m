//
//  main.m
//  macdown-cmd
//
//  Created by Esben Sorig on 30/06/2014.
//  Copyright (c) 2014 Tzu-ping Chung . All rights reserved.
//

#import "MPCommandInput.h"
#import <AppKit/AppKit.h>
#import <GBCli/GBCli.h>
#import "NSUserDefaults+Suite.h"
#import "MPGlobals.h"
#import "MPArgumentProcessor.h"




NSRunningApplication *MPRunningMacDownInstance()
{
    NSArray *runningInstances = [NSRunningApplication
        runningApplicationsWithBundleIdentifier:kMPApplicationSuiteName];
    return runningInstances.firstObject;
}

void MPCollectPipedContentURLForMacDown(NSURL *url) {
    NSUserDefaults *defaults =
        [[NSUserDefaults alloc] initWithSuiteNamed:kMPApplicationSuiteName];
    
    [defaults setObject:url.path forKey:kMPPipedContentFileToOpen inSuiteNamed:kMPApplicationSuiteName];
    [defaults synchronize];
}

void MPCollectForMacDown(NSOrderedSet<NSURL *> *urls)
{
    NSUserDefaults *defaults =
        [[NSUserDefaults alloc] initWithSuiteNamed:kMPApplicationSuiteName];
    NSMutableArray<NSString *> *urlStrings =
        [[NSMutableArray alloc] initWithCapacity:urls.count];
    for (NSURL *url in urls)
        [urlStrings addObject:url.path];
    [defaults setObject:urlStrings forKey:kMPFilesToOpenKey
           inSuiteNamed:kMPApplicationSuiteName];
    [defaults synchronize];
}

void MPCollectFoldersForMacDown(NSOrderedSet<NSURL *> *urls)
{
    NSUserDefaults *defaults =
        [[NSUserDefaults alloc] initWithSuiteNamed:kMPApplicationSuiteName];
    NSMutableArray<NSString *> *paths =
        [[NSMutableArray alloc] initWithCapacity:urls.count];
    for (NSURL *url in urls)
        [paths addObject:url.path];
    [defaults setObject:paths forKey:kMPFoldersToOpenKey
           inSuiteNamed:kMPApplicationSuiteName];
    [defaults synchronize];
}

int main(int argc, const char * argv[])
{
    @autoreleasepool
    {
        MPArgumentProcessor *argproc = [[MPArgumentProcessor alloc] init];

        if (argproc.printsHelp)
            [argproc printHelp:YES];
        else if (argproc.printsVersion)
            [argproc printVersion:YES];
        
        NSError *inputError = nil;
        NSData *dataFromPipe = MPReadCommandInput(STDIN_FILENO, &inputError);
        if (inputError) {
            fprintf(stderr, "Could not read standard input: %s\n", inputError.localizedDescription.UTF8String);
            return EXIT_FAILURE;
        }
        
        if (dataFromPipe) {
            // Store piped content in a temporary file which will be read by MacDown on launch
            NSString *fileName = [NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], @"pipedText.txt"];
            NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
            
            NSError *writeError = nil;
            if (![dataFromPipe writeToFile:fileURL.path options:NSDataWritingAtomic error:&writeError]) {
                fprintf(stderr, "Could not save piped input: %s\n", writeError.localizedDescription.UTF8String);
                return EXIT_FAILURE;
            }
            MPCollectPipedContentURLForMacDown(fileURL);
        }

        // Treat all arguments as file names to open. Convert them to absolute
        // paths and store them (as an array) in MacDown's user defaults to
        // be opened later.
        NSString *pwd = [NSFileManager defaultManager].currentDirectoryPath;
        NSFileManager *fm = [NSFileManager defaultManager];
        NSMutableOrderedSet<NSURL *> *fileURLs = [NSMutableOrderedSet orderedSet];
        NSMutableOrderedSet<NSURL *> *folderURLs = [NSMutableOrderedSet orderedSet];
        for (NSString *arg in argproc.arguments)
        {
            NSURL *url = MPCommandFileURL(arg, pwd);
            BOOL isDir = NO;
            if ([fm fileExistsAtPath:url.path isDirectory:&isDir] && isDir)
                [folderURLs addObject:url];
            else
                [fileURLs addObject:url];
        }
        // Both run unconditionally: each overwrites its key, so an empty set
        // clears whatever a previous invocation left behind. Skipping the empty
        // one would leave that list to be opened on the next launch.
        MPCollectForMacDown(fileURLs);
        MPCollectFoldersForMacDown(folderURLs);

        // Launch MacDown.
        BOOL launched = [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:kMPApplicationBundleIdentifier options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifier:nil];
        if (!launched) {
            fprintf(stderr, "Could not launch %s\n", kMPApplicationBundleIdentifier.UTF8String);
            return EXIT_FAILURE;
        }
    }
    return EXIT_SUCCESS;
}

