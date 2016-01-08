//
//  ServerCFMessagePort.m
//  ipc
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import "ServerCFMessagePort.h"

#import "SharedCFMessagePort.h"

@interface ServerCFMessagePort ()

@property (strong, nonatomic) __attribute__((NSObject)) CFMessagePortRef port;

@end

@implementation ServerCFMessagePort

@synthesize requestHandler = _requestHandler;

- (void)startServer
{
    CFMessagePortContext context;
    memset(&context, 0, sizeof(CFMessagePortContext));
    context.info = (__bridge void *)self;

    CFMessagePortRef port = CFMessagePortCreateLocal(kCFAllocatorDefault, MessagePortServiceName, messagePortCallBack, &context, NULL);
    self.port = port;

    CFRunLoopSourceRef source = CFMessagePortCreateRunLoopSource(kCFAllocatorDefault, port, 0);
    CFRunLoopAddSource(CFRunLoopGetMain(), source, kCFRunLoopDefaultMode);
}

CFDataRef messagePortCallBack(CFMessagePortRef local, SInt32 msgid, CFDataRef data, void *info)
{
    if (msgid != MessagePortRequestImageId) {
        return NULL;
    }

    ServerCFMessagePort *self = (__bridge ServerCFMessagePort *)info;
    if (self == nil) {
        return nil;
    }

    NSString *request = [[NSString alloc] initWithData:(__bridge NSData *)data encoding:NSUTF8StringEncoding];
    if (request == nil) {
        return NULL;
    }

    NSImage *image = self.requestHandler(request);
    if (image == nil) {
        return NULL;
    }

    return CFRetain((__bridge CFDataRef)[image TIFFRepresentation]);
}

@end
