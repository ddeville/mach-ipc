//
//  ServerDistributedObjects.m
//  ipc
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import "ServerDistributedObjects.h"

#import "SharedDistributedObjects.h"

@interface ServerDistributedObjects () <ServerProtocol>

@property (strong, nonatomic) NSConnection *connection;

@end

@implementation ServerDistributedObjects

@synthesize requestHandler = _requestHandler;

- (void)startServer
{
    // NSConnection needs a service runloop so make sure we're on the main thread (we could service a runloop on a background thread too...)
    NSAssert([NSThread isMainThread], @"The server needs a serviced runloop and should be started on the main thread");

    NSConnection *connection = [NSConnection connectionWithReceivePort:[NSPort port] sendPort:nil];
    connection.rootObject = self;
    
    [connection registerName:DistributedObjectsServiceName];

    self.connection = connection;
}

#pragma mark - ConnectionProtocol

- (NSData *)requestImage:(NSString *)request
{
    NSImage *image = self.requestHandler(request);
    return [NSKeyedArchiver archivedDataWithRootObject:image];
}

@end
