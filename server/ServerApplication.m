//
//  ServerApplication.m
//  Server
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import "ServerApplication.h"

@interface ServerApplication (/* Bindings */)

@property (copy, nonatomic) NSAttributedString *log;

@end

@implementation ServerApplication

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [self _appendToLog:@"Server launched"];
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
