//
//  ClientCFMessagePort.m
//  ipc
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import "ClientCFMessagePort.h"

#import "SharedCFMessagePort.h"

@implementation ClientCFMessagePort

- (void)requestImage:(NSString *)name completion:(void(^)(NSImage *image))completion
{
    // CFMessagePort needs a service runloop so make sure we're on the main thread (we could service a runloop on a background thread too...)
    NSAssert([NSThread isMainThread], @"The client needs a serviced runloop and should be called on the main thread");

    CFMessagePortRef port = CFMessagePortCreateRemote(kCFAllocatorDefault, MessagePortServiceName);
    if (port == NULL) {
        return;
    }

    CFDataRef data = (__bridge CFDataRef)[name dataUsingEncoding:NSUTF8StringEncoding];

    CFDataRef imageData = NULL;
    SInt32 sent = CFMessagePortSendRequest(port, MessagePortRequestImageId, data, 5.0, 5.0, kCFRunLoopDefaultMode, &imageData);
    CFRelease(port);

    if (sent != kCFMessagePortSuccess) {
        return;
    }

    NSImage *image = [[NSImage alloc] initWithData:(__bridge NSData *)imageData];

    completion(image);
}

@end
