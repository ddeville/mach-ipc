//
//  ServerNSXPCConnection.m
//  ipc
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import "ServerNSXPCConnection.h"

#import "shared-xpc-connection.h"

@interface ServerNSXPCConnection () <NSXPCListenerDelegate, ConnectionProtocol>

@property (strong, nonatomic) NSXPCListener *listener;

@end

@implementation ServerNSXPCConnection

@synthesize requestHandler = _requestHandler;

- (void)startServer
{
    NSXPCListener *listener = [[NSXPCListener alloc] initWithMachServiceName:XPCMachServiceName];
    listener.delegate = self;
    self.listener = listener;

    [listener resume];
}

#pragma mark - NSXPCListenerDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)connection
{
    NSXPCInterface *interface = [NSXPCInterface interfaceWithProtocol:@protocol(ConnectionProtocol)];
    [interface setClasses:[NSSet setWithObject:[NSString class]] forSelector:@selector(requestImage:completion:) argumentIndex:0 ofReply:NO];
    [interface setClasses:[NSSet setWithObject:[NSImage class]] forSelector:@selector(requestImage:completion:) argumentIndex:0 ofReply:YES];

    connection.exportedInterface = interface;
    connection.exportedObject = self;

    [connection resume];

    return YES;
}

#pragma mark - ConnectionProtocol

- (void)requestImage:(NSString *)name completion:(void(^)(NSImage *image))completion
{
    NSImage *image = self.requestHandler(name);
    completion(image);
}

@end
