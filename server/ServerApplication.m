//
//  ServerApplication.m
//  Server
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import "ServerApplication.h"

#import "Shared.h"
#import "Server.h"
#import "ServerNSXPCConnection.h"

#define MANAGE_CLIENT   0

@interface ServerApplication (/* Bindings */)

@property (copy, nonatomic) NSAttributedString *log;

@end

@interface ServerApplication ()

@property (strong, nonatomic) id <Server> server;

@end

@implementation ServerApplication

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    self.server = [[NSClassFromString(ServerClasses[CONNECTION_TYPE]) alloc] init];

    __weak ServerApplication *weakServer = self;
    self.server.requestHandler = ^NSImage *(NSString *request) {
        __strong ServerApplication *server = weakServer;

        dispatch_async(dispatch_get_main_queue(), ^{
            [server _appendToLog:[NSString stringWithFormat:@"Received request \"%@\"", request]];
        });

        return [[NSBundle mainBundle] imageForResource:request];
    };

    [self.server startServer];

    [self _appendToLog:@"Server started"];
    
#if MANAGE_CLIENT
    [self _launchClientIfNeeded];
#endif /* MANAGE_CLIENT */
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
#if MANAGE_CLIENT
    NSRunningApplication *client = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.ddeville.client"].firstObject;
    [client terminate];
#endif /* MANAGE_CLIENT */
}

- (void)_appendToLog:(NSString *)string
{
    if (string == nil) {
        return;
    }

    NSMutableString *log = [NSMutableString stringWithString:(self.log.string ?: @"")];
    if (log.length != 0) {
        [log appendString:@"\n\n"];
    }

    NSString *time = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle];
    NSString *server = NSStringFromClass([self.server class]);
    [log appendFormat:@"%@ (%@): %@", time, server, string];

    self.log = [[NSAttributedString alloc] initWithString:log attributes:nil];
}

- (void)_launchClientIfNeeded
{
    NSArray *clients = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.ddeville.client"];
    [clients makeObjectsPerformSelector:@selector(terminate)];
    
    NSString *clientPath = [[NSBundle mainBundle] pathForResource:@"client" ofType:@"app"];
    [[NSWorkspace sharedWorkspace] performSelector:@selector(launchApplication:) withObject:clientPath afterDelay:0.1];
    
    [self _appendToLog:@"Launched client"];
}

@end
