//
//  xpc-connection.h
//  ipc
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import <Cocoa/Cocoa.h>

static NSString * const XPCMachServiceName = @"com.ddeville.me";

@protocol ConnectionProtocol <NSObject>

- (void)requestImage:(NSString *)name completion:(void(^)(NSImage *image))completion;

@end
