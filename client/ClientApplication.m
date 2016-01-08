//
//  ClientApplication.m
//  client
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import "ClientApplication.h"

#import "Shared.h"
#import "Client.h"
#import "ClientNSXPCConnection.h"

@interface ClientApplication (/* Bindings */)

@property (copy, nonatomic) NSAttributedString *log;
@property (copy, nonatomic) NSImage *image;

@end

@interface ClientApplication ()

@property (strong, nonatomic) id <Client> client;

@end

@implementation ClientApplication

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [self _appendToLog:@"Client launched"];

    self.client = [[NSClassFromString(ClientClasses[CONNECTION_TYPE]) alloc] init];
}

- (IBAction)requestImage:(id)sender
{
    [self _appendToLog:@"Requesting image"];

    [self.client requestImage:@"dolan" completion:^(NSImage *image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.image = image;

            [self _appendToLog:[NSString stringWithFormat:@"Received image %@", image]];
        });
    }];
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
