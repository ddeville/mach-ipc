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

@property (strong, nonatomic) NSArray<id <Server>> *servers;

@end

@implementation ServerApplication

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    __weak typeof(self) welf = self;
    NSImage *(^requestHandler)(id <Server>, NSString *) = ^NSImage *(id <Server> server, NSString *request) {
        __strong typeof(welf) strelf = welf;
        
        NSImage *image = [[NSBundle mainBundle] imageForResource:request];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [strelf _appendToLog:[NSString stringWithFormat:@"Received request on server %@: \"%@\"", server, request]];
            [strelf _appendToLog:[NSString stringWithFormat:@"Responding from server %@ with image %@", server, image]];
        });
        
        return image;
    };
    
    NSMutableArray *servers = [NSMutableArray array];
    
    for (int idx; idx < sizeof(ServerClasses) / sizeof(NSString *); idx++) {
        id <Server> server = [[NSClassFromString(ServerClasses[idx]) alloc] init];
        server.requestHandler = requestHandler;
        [server startServer];
        [servers addObject:server];
        [self _appendToLog:[NSString stringWithFormat:@"%@ started", [server class]]];
    }
    
    self.servers = servers;
    
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
    [log appendFormat:@"%@: %@", time, string];

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
