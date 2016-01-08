//
//  ServerNSPortMessage.m
//  ipc
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import "ServerNSPortMessage.h"

#import "SharedNSPortMessage.h"

@interface ServerNSPortMessage () <NSPortDelegate>

@property (strong, nonatomic) NSPort *port;

@end

@implementation ServerNSPortMessage

@synthesize requestHandler = _requestHandler;

- (void)startServer
{
    NSPort *port = [NSMachPort port];
    port.delegate = self;
    self.port = port;

    [[NSMachBootstrapServer sharedInstance] registerPort:port name:PortMessageServiceName];

    [port scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

#pragma mark - NSPortDelegate

- (void)handlePortMessage:(NSPortMessage *)message
{
    if (message.msgid != PortMessageRequestImageId) {
        return;
    }

    if (message.components.count != 1) {
        return;
    }

    if (message.sendPort == nil) {
        return;
    }

    NSData *nameData = message.components[0];
    NSString *name = [[NSString alloc] initWithData:nameData encoding:NSUTF8StringEncoding];

    NSImage *image = self.requestHandler(name);
    if (image == nil) {
        return;
    }

    NSData *imageData = image.TIFFRepresentation;

    NSPortMessage *replyMessage = [[NSPortMessage alloc] initWithSendPort:message.sendPort receivePort:nil components:@[nameData, imageData]];
    replyMessage.msgid = PortMessageResponseImageId;

    [replyMessage sendBeforeDate:[NSDate distantFuture]];
}

@end
