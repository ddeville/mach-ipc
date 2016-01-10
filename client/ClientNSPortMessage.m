//
//  ClientNSPortMessage.m
//  ipc
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import "ClientNSPortMessage.h"

#import "SharedNSPortMessage.h"

@interface ClientNSPortMessage () <NSPortDelegate>

@property (strong, nonatomic) NSPort *port;

// No need to lock the requests because everything happens on the main runloop
@property (strong, nonatomic) NSMutableDictionary *pendingRequests;

@end

@implementation ClientNSPortMessage

- (instancetype)init
{
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _port = [NSPort port];
    _port.delegate = self;

    [_port scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];

    _pendingRequests = [NSMutableDictionary dictionary];

    return self;
}

- (void)requestImage:(NSString *)name completion:(void (^)(NSImage *))completion
{
    // NSPortMessage needs a serviced runloop so make sure we're on the main thread (we could service a runloop on a background thread too...)
    NSAssert([NSThread isMainThread], @"The client needs a serviced runloop and should be called on the main thread");
    
    NSPort *serverPort = [[NSMachBootstrapServer sharedInstance] portForName:PortMessageServiceName];
    if (serverPort == nil) {
        return;
    }

    [self.pendingRequests setObject:completion forKey:name];

    NSData *request = [name dataUsingEncoding:NSUTF8StringEncoding];

    NSPortMessage *message = [[NSPortMessage alloc] initWithSendPort:serverPort receivePort:self.port components:@[request]];
    message.msgid = PortMessageRequestImageId;

    [message sendBeforeDate:[NSDate distantFuture]];
}

#pragma mark - NSPortDelegate

- (void)handlePortMessage:(NSPortMessage *)message
{
    if (message.components.count != 2) {
        return;
    }

    NSString *name = [[NSString alloc] initWithData:message.components[0] encoding:NSUTF8StringEncoding];
    if (name == nil) {
        return;
    }

    void (^completion)(NSImage *) = self.pendingRequests[name];
    [self.pendingRequests removeObjectForKey:name];

    if (completion == nil) {
        return;
    }

    NSImage *image = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:message.components[1] error:NULL];
    if (image == nil) {
        return;
    }

    completion(image);
}

@end
