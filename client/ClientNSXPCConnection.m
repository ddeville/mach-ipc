//
//  ClientNSXPCConnection.m
//  ipc
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import "ClientNSXPCConnection.h"

#import "SharedNSXPCConnection.h"

@implementation ClientNSXPCConnection

- (void)requestImage:(NSString *)name completion:(void(^)(NSImage *image, NSError *error))completion
{
    NSXPCConnection *connection = [[NSXPCConnection alloc] initWithMachServiceName:XPCMachServiceName options:(NSXPCConnectionOptions)0];

    NSXPCInterface *interface = [NSXPCInterface interfaceWithProtocol:@protocol(ConnectionProtocol)];
    [interface setClasses:[NSSet setWithObject:[NSString class]] forSelector:@selector(requestImage:completion:) argumentIndex:0 ofReply:NO];
    [interface setClasses:[NSSet setWithObject:[NSImage class]] forSelector:@selector(requestImage:completion:) argumentIndex:0 ofReply:YES];
    connection.remoteObjectInterface = interface;

    id <ConnectionProtocol> server = [connection remoteObjectProxyWithErrorHandler:^(NSError *error) {
        completion(nil, error);
    }];

    [connection resume];
    [server requestImage:name completion:^(NSImage *image) {
        if (image == nil) {
            completeWithDefaultError(completion);
        } else {
            completion(image, nil);
        }
    }];
}

@end
