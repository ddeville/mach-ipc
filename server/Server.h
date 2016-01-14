//
//  Server.h
//  ipc
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol Server <NSObject>

- (void)startServer;

@property (copy, nonatomic) NSImage *(^requestHandler)(id <Server>, NSString *request);

@end
