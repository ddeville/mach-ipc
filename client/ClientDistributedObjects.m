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

- (void)requestImage:(NSString *)name completion:(void(^)(NSImage *image))completion
{
    // NSConnection needs a service runloop so make sure we're on the main thread (we could service a runloop on a background thread too...)
    NSAssert([NSThread isMainThread], @"The client needs a serviced runloop and should be called on the main thread");

    NSConnection *connection = [NSConnection connectionWithRegisteredName:DistributedObjectsServiceName host:nil];

    NSDistantObject *proxy = [connection rootProxy];
    [proxy setProtocolForProxy:@protocol(ServerProtocol)];

    id <ServerProtocol> server = (id <ServerProtocol>)proxy;

    NSData *data = [server requestImage:name];
    if (data == nil) {
        return;
    }

    NSImage *image = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:NULL];
    if (image == nil) {
        return;
    }

    completion(image);
}

@end
