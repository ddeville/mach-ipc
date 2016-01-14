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

- (void)requestImage:(NSString *)name completion:(void(^)(NSImage *image, NSError *error))completion
{
    // since the request is synchronous, run it on a background queue
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self _actuallyRequestImage:name completion:completion];
    });
}

- (void)_actuallyRequestImage:(NSString *)name completion:(void(^)(NSImage *image, NSError *error))completion
{
    CFMessagePortRef port = CFMessagePortCreateRemote(kCFAllocatorDefault, MessagePortServiceName);
    if (port == NULL) {
        completeWithDefaultError(completion);
        return;
    }
    
    CFDataRef data = (__bridge CFDataRef)[name dataUsingEncoding:NSUTF8StringEncoding];
    
    CFDataRef imageData = NULL;
    SInt32 sent = CFMessagePortSendRequest(port, MessagePortRequestImageId, data, 5.0, 5.0, kCFRunLoopDefaultMode, &imageData);
    CFRelease(port);
    
    if (sent != kCFMessagePortSuccess) {
        completeWithDefaultError(completion);
        return;
    }
    
    NSImage *image = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:(__bridge NSData *)imageData error:NULL];
    if (image == nil) {
        completeWithDefaultError(completion);
        return;
    }
    
    completion(image, nil);
}

@end
