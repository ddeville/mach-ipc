//
//  ClientApplication.m
//  client
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import "ClientApplication.h"

@interface ClientApplication (/* Bindings */)

@property (copy, nonatomic) NSAttributedString *log;
@property (copy, nonatomic) NSImage *image;

@end

@implementation ClientApplication

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [self _appendToLog:@"Client launched"];
}

- (IBAction)requestImage:(id)sender
{

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
