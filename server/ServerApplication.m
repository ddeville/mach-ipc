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

        return [NSImage imageNamed:request];
    };

    [self.server startServer];

    [self _appendToLog:@"Server started"];
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

@end
