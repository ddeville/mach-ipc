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
@property (strong, nonatomic) NSArray *clientClassNames;
@property (assign, nonatomic) BOOL loading;

@property (strong, nonatomic) IBOutlet NSTextView *logTextView;

@end

@implementation ClientApplication

+ (void)load
{
    @autoreleasepool {
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"selectedClient": ClientClasses[0]}];
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    self.clientClassNames = [NSArray arrayWithObjects:ClientClasses count:(sizeof(ClientClasses) / sizeof(NSString *))];
}

- (IBAction)requestImage:(id)sender
{
    NSString *filename = @"goobypls";
    
    NSString *clientClass = [[NSUserDefaults standardUserDefaults] stringForKey:@"selectedClient"];
    id <Client> client = [[NSClassFromString(clientClass) alloc] init];
    
    [self _appendToLog:[NSString stringWithFormat:@"Requesting image \"%@\"", filename] client:client];
    
    self.image = nil;
    self.loading = YES;

    [client requestImage:filename completion:^(NSImage *image, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.loading = NO;
            self.image = image;

            if (image != nil) {
                [self _appendToLog:[NSString stringWithFormat:@"Received image %@", image] client:client];
            } else {
                [self _appendToLog:[NSString stringWithFormat:@"Received error %@", error] client:client];
            }
        });
    }];
}

- (void)_appendToLog:(NSString *)string client:(id <Client>)client
{
    if (string == nil) {
        return;
    }
    
    NSMutableString *log = [NSMutableString stringWithString:(self.log.string ?: @"")];
    if (log.length != 0) {
        [log appendString:@"\n\n"];
    }

    NSString *time = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle];
    [log appendFormat:@"%@ (%@): %@", time, NSStringFromClass([client class]), string];

    self.log = [[NSAttributedString alloc] initWithString:log attributes:nil];
    
    [self.logTextView scrollToEndOfDocument:nil];
}

@end
