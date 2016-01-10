//
//  ServerMach.m
//  ipc
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import "ServerMach.h"

#import <mach/mach.h>
#import <servers/bootstrap.h>

#import "SharedMach.h"

@interface ServerMach ()

@property (assign, nonatomic) mach_port_t port;
@property (strong, nonatomic) dispatch_source_t source;

@end

@implementation ServerMach

@synthesize requestHandler = _requestHandler;

- (void)startServer
{
    mach_port_t port;
    kern_return_t ret = bootstrap_check_in(bootstrap_port, mach_service_name, &port);
    if (ret != BOOTSTRAP_SUCCESS) {
        return;
    }
    
    self.port = port;
    
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_MACH_RECV, port, 0, dispatch_get_main_queue());
    self.source = source;
    
    __weak ServerMach *weakSelf = self;
    dispatch_source_set_event_handler(source, ^{
        __strong ServerMach *server = weakSelf;
        [server _handleRequest];
    });
    dispatch_resume(source);
}

- (void)_handleRequest
{
    mach_request_receiver_msg_t request;
    request.header.msgh_size = sizeof(mach_request_receiver_msg_t);
    request.header.msgh_local_port = self.port;

    kern_return_t received = mach_msg(&request.header, MACH_RCV_MSG, 0, request.header.msgh_size, self.port, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
    if (received != MACH_MSG_SUCCESS) {
        return;
    }
    
    mach_port_t reply_port = request.header.msgh_remote_port;
    if (reply_port == MACH_PORT_NULL) {
        return;
    }
    
    NSString *filename = [NSString stringWithUTF8String:request.filename];
    
    NSImage *image = self.requestHandler(filename);
    if (image == nil) {
        return;
    }
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:image];
    if (data == nil) {
        return;
    }
    
    mach_response_msg_t response;
    memset(&response, 0, sizeof(mach_response_msg_t));
    
    response.header.msgh_bits = MACH_MSGH_BITS_LOCAL(request.header.msgh_bits) | MACH_MSGH_BITS_COMPLEX;
    response.header.msgh_size = sizeof(mach_response_msg_t);
    response.header.msgh_remote_port = reply_port;
    response.header.msgh_local_port = MACH_PORT_NULL;
    response.header.msgh_id = request.header.msgh_id;
    
    response.body.msgh_descriptor_count = 1;
    
    response.data.type = MACH_MSG_OOL_DESCRIPTOR;
    response.data.copy = MACH_MSG_VIRTUAL_COPY;
    response.data.address = (void *)data.bytes;
    response.data.size = (mach_msg_size_t)data.length;
    response.data.deallocate = false;
    
    mach_msg(&response.header, MACH_SEND_MSG, response.header.msgh_size, 0, MACH_PORT_NULL, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
}

@end
