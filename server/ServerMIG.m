//
//  ServerMIG.m
//  ipc
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import "ServerMIG.h"

#import <mach/bootstrap.h>
#import <servers/bootstrap.h>

#import "SharedMIG.h"
#import "shared_migServer.h"

@interface ServerMIG ()

@property (assign, nonatomic) mach_port_t port;
@property (strong, nonatomic) dispatch_queue_t server_queue;

@end

@implementation ServerMIG

@synthesize requestHandler = _requestHandler;

extern boolean_t shared_mig_server(mach_msg_header_t *InHeadP, mach_msg_header_t *OutHeadP);

- (void)startServer
{
    mach_port_t port;
    kern_return_t ret = bootstrap_check_in(bootstrap_port, mig_mach_service_name, &port);
    if (ret != BOOTSTRAP_SUCCESS) {
        return;
    }
    
    self.port = port;
    
    dispatch_queue_t server_queue = dispatch_queue_create("mig-server", DISPATCH_QUEUE_SERIAL);
    self.server_queue = server_queue;
    
    dispatch_async(server_queue, ^{
#warning Change size
        mach_msg_server(shared_mig_server, 1024, port, MACH_MSG_TIMEOUT_NONE);
    });
}

kern_return_t request_image(mach_port_t server_port, request_input_t request, vm_offset_t *data, mach_msg_type_number_t *data_len)
{
    NSString *filename = [NSString stringWithUTF8String:request];
    
#warning Call the requestHandler to retrieve the image
    NSImage *image = [[NSBundle mainBundle] imageForResource:filename];
    
    NSData *imageData = [NSKeyedArchiver archivedDataWithRootObject:image];
    
    *data = (vm_offset_t)imageData.bytes;
    *data_len = (mach_msg_type_number_t)imageData.length;
    
    return MACH_MSG_SUCCESS;
}

@end
