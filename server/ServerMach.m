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
    mach_msg_header_t *msg = (mach_msg_header_t *)calloc(1, 2048);
    msg->msgh_size = 2048;
    
    while (1) {
        msg->msgh_bits = 0;
        msg->msgh_local_port = self.port;
        msg->msgh_remote_port = MACH_PORT_NULL;
        msg->msgh_id = 0;
        
        mach_msg_option_t options = (MACH_RCV_MSG | MACH_RCV_LARGE | MACH_RCV_TRAILER_TYPE(MACH_MSG_TRAILER_FORMAT_0) | MACH_RCV_TRAILER_ELEMENTS(MACH_RCV_TRAILER_AV));
        kern_return_t ret = mach_msg(msg, options, 0, msg->msgh_size, self.port, 0, MACH_PORT_NULL);
        if (ret == MACH_MSG_SUCCESS) {
            break;
        }
        assert(ret != MACH_RCV_TOO_LARGE);
        
        uint32_t size = round_msg(msg->msgh_size + MAX_TRAILER_SIZE);
        msg = realloc(msg, size);
        msg->msgh_size = size;
    }
    
    dispatch_async(self.queue, ^{
        
    });
}

@end
