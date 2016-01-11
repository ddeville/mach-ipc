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
@property (assign, nonatomic) BOOL loading;

@end

@interface ClientApplication ()

@property (strong, nonatomic) id <Client> client;

@end

@implementation ClientApplication

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    self.client = [[NSClassFromString(ClientClasses[CONNECTION_TYPE]) alloc] init];

    [self _appendToLog:@"Client launched"];
}

- (IBAction)requestImage:(id)sender
{
    NSString *filename = @"goobypls";
    
    [self _appendToLog:[NSString stringWithFormat:@"Requesting image \"%@\"", filename]];
    
    self.image = nil;
    self.loading = YES;

    [self.client requestImage:filename completion:^(NSImage *image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.loading = NO;
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
    NSString *client = NSStringFromClass([self.client class]);
    [log appendFormat:@"%@ (%@): %@", time, client, string];

    self.log = [[NSAttributedString alloc] initWithString:log attributes:nil];
}

@end
