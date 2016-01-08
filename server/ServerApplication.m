//
//  ServerApplication.m
//  Server
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import "ServerApplication.h"

#import "shared.h"

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
    [self _appendToLog:@"Server launched"];

    self.server = [[NSClassFromString(ServerClasses[CONNECTION_TYPE]) alloc] init];

    __weak ServerApplication *weakServer = self;
    self.server.requestHandler = ^NSImage *(NSString *request) {
        __strong ServerApplication *server = weakServer;
        [server _appendToLog:[NSString stringWithFormat:@"Received request \"%@\"", request]];
        return [NSImage imageNamed:request];
    };

    [self.server startServer];
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

@end
