//
//  ClientMach.m
//  ipc
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import "ClientMach.h"

#import <mach/mach.h>
#import <servers/bootstrap.h>

#import "SharedMach.h"

@interface ClientMach ()

@property (strong, nonatomic) NSMutableDictionary *inflightSources;

@end

@implementation ClientMach

- (instancetype)init
{
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    _inflightSources = [NSMutableDictionary dictionary];
    
    return self;
}

- (void)requestImage:(NSString *)name completion:(void(^)(NSImage *image))completion
{
    // look up the server port by name with the bootstrap server
    mach_port_t server_port;
    kern_return_t looked_up = bootstrap_look_up(bootstrap_port, mach_service_name, &server_port);
    if (looked_up != BOOTSTRAP_SUCCESS) {
        return;
    }
    
    // allocate a new port with receive right for our client to receive data from the server
    mach_port_t client_port;
    kern_return_t allocated = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &client_port);
    if (allocated != BOOTSTRAP_SUCCESS) {
        mach_port_deallocate(mach_task_self(), server_port);
        return;
    }
    
    // create a new request to send to the server and send it
    // note that we use `MACH_MSG_TYPE_COPY_SEND` for the remote port to denote that the message carries a send right (`server_port`)
    // and `MACH_MSG_TYPE_MAKE_SEND` to denote that a send right is created from the supplied receive right (`client_port`)
    mach_request_msg_t request;
    request.header.msgh_bits = MACH_MSGH_BITS(MACH_MSG_TYPE_COPY_SEND, MACH_MSG_TYPE_MAKE_SEND);
    request.header.msgh_size = sizeof(mach_request_msg_t);
    request.header.msgh_remote_port = server_port;
    request.header.msgh_local_port = client_port;
    request.header.msgh_id = mach_message_request_image_id;

    strncpy(request.filename, name.UTF8String, PATH_MAX);
    
    kern_return_t sent = mach_msg(&request.header, MACH_SEND_MSG, request.header.msgh_size, 0, MACH_PORT_NULL, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
    mach_port_deallocate(mach_task_self(), server_port);
    if (sent != MACH_MSG_SUCCESS) {
        mach_port_deallocate(mach_task_self(), client_port);
        return;
    }
    
    // monitor the client port for recv events (the reply from the server) asynchronously via a dispatch source (rather than blocking on `mach_msg`)
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_MACH_RECV, client_port, 0, dispatch_get_main_queue());
    dispatch_source_set_event_handler(source, ^{
        // create a response that we will read into, making sure to use the receiver version that accounts for the msg trailer
        mach_response_receiver_msg_t response;
        response.header.msgh_size = sizeof(mach_response_receiver_msg_t);
        response.header.msgh_local_port = client_port;
        
        kern_return_t received = mach_msg(&response.header, MACH_RCV_MSG, 0, response.header.msgh_size, client_port, 0, MACH_PORT_NULL);
        mach_port_deallocate(mach_task_self(), client_port);
        if (received != MACH_MSG_SUCCESS) {
            return;
        }

        if (response.data.address == NULL) {
            return;
        }
        
        // retrieve the data from the response and unarchive it to get the image
        NSData *data = [NSData dataWithBytes:response.data.address length:response.data.size];
        vm_deallocate(mach_task_self(), (vm_address_t)response.data.address, response.data.size);
        if (data == nil) {
            return;
        }
        
        NSImage *image = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:NULL];
        if (image == nil) {
            return;
        }
        
        completion(image);
        
        // now that we succeeded, make sure to remove the source from our map so that it can be freed
        [self.inflightSources removeObjectForKey:name];
    });
    dispatch_resume(source);
    
    // add the source to a map on the object so that ARC doesn't dealloc it while we're waiting for events...
    [self.inflightSources setObject:source forKey:name];
}

@end
