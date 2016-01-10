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

@property (strong, nonatomic) dispatch_queue_t queue;
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
    
    dispatch_queue_attr_t queue_attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qos_class_main(), 0);
    dispatch_queue_t queue = dispatch_queue_create("com.ddeville.ipc.mach", queue_attr);
    self.queue = queue;
    
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_MACH_RECV, port, 0, queue);
    __weak ServerMach *weakSelf = self;
    dispatch_source_set_event_handler(source, ^{
        __strong ServerMach *server = weakSelf;
        [server _handleRequest];
    });
    self.source = source;
    dispatch_resume(source);
}

- (void)_handleRequest
{
    mach_request_msg_t *request = (mach_request_msg_t *)calloc(1, 2048);
    request->header.msgh_size = 2048;
    
    while (1) {
        request->header.msgh_bits = 0;
        request->header.msgh_local_port = self.port;
        request->header.msgh_remote_port = MACH_PORT_NULL;
        request->header.msgh_id = 0;
        
        mach_msg_option_t options = (MACH_RCV_MSG | MACH_RCV_LARGE | MACH_RCV_TRAILER_TYPE(MACH_MSG_TRAILER_FORMAT_0) | MACH_RCV_TRAILER_ELEMENTS(MACH_RCV_TRAILER_AV));
        kern_return_t ret = mach_msg(&request->header, options, 0, request->header.msgh_size, self.port, 0, MACH_PORT_NULL);
        if (ret == MACH_MSG_SUCCESS) {
            break;
        }
        assert(ret != MACH_RCV_TOO_LARGE);
        
        uint32_t size = round_msg(request->header.msgh_size + MAX_TRAILER_SIZE);
        request = realloc(request, size);
        request->header.msgh_size = size;
    }
    
    mach_port_t reply_port = request->header.msgh_remote_port;
    if (reply_port == MACH_PORT_NULL) {
        return;
    }
    
    NSString *name = [NSString stringWithUTF8String:request->request];
    if (name == nil) {
        return;
    }
    
    NSImage *image = self.requestHandler(name);
    if (image == nil) {
        return;
    }
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:image];
    
    mach_response_msg_t *response = (mach_response_msg_t *)calloc(1, sizeof(mach_msg_header_t) + sizeof(size_t) + data.length);
    response->data_size = data.length;
    memcpy(response->data, data.bytes, data.length);
    
    response->header.msgh_bits = MACH_MSGH_BITS(MACH_MSG_TYPE_COPY_SEND, MACH_MSG_TYPE_MAKE_SEND);
    response->header.msgh_size = (mach_msg_size_t)(sizeof(mach_msg_header_t) + sizeof(size_t) + data.length);
    response->header.msgh_remote_port = reply_port;
    response->header.msgh_local_port = MACH_PORT_NULL;
    response->header.msgh_id = mach_message_request_image_id;
    
    kern_return_t ret = mach_msg(&response->header, MACH_SEND_MSG, response->header.msgh_size, 0, MACH_PORT_NULL, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
}

@end
