//
//  ClientDistributedObjects.m
//  ipc
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import "ClientDistributedObjects.h"

#import "SharedDistributedObjects.h"

@implementation ClientDistributedObjects

- (void)requestImage:(NSString *)name completion:(void(^)(NSImage *image, NSError *error))completion
{
    // since the request is synchronous, run it on a background queue
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self _actuallyRequestImage:name completion:completion];
    });
}

- (void)_actuallyRequestImage:(NSString *)name completion:(void(^)(NSImage *image, NSError *error))completion
{
    NSConnection *connection = [NSConnection connectionWithRegisteredName:DistributedObjectsServiceName host:nil];
    
    NSDistantObject *proxy = [connection rootProxy];
    [proxy setProtocolForProxy:@protocol(ServerProtocol)];
    
    id <ServerProtocol> server = (id <ServerProtocol>)proxy;
    
    NSData *data = [server requestImage:name];
    if (data == nil) {
        completeWithDefaultError(completion);
        return;
    }
    
    NSImage *image = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:NULL];
    if (image == nil) {
        completeWithDefaultError(completion);
        return;
    }
    
    completion(image, nil);
}

@end
