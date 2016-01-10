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

@property (strong, nonatomic) NSMutableDictionary *sourceQueue;

@end

@implementation ClientMach

- (instancetype)init
{
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    _sourceQueue = [NSMutableDictionary dictionary];
    
    return self;
}

- (void)requestImage:(NSString *)name completion:(void(^)(NSImage *image))completion
{
    kern_return_t ret;
    
    mach_port_t bs = bootstrap_port;
    
    mach_port_t server_port;
    ret = bootstrap_look_up(bs, mach_service_name, &server_port);
    
    if (ret != BOOTSTRAP_SUCCESS) {
        return;
    }
    
    mach_port_t client_port;
    ret = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &client_port);
    
    if (ret != BOOTSTRAP_SUCCESS) {
        return;
    }
    
    mach_request_msg_t send_msg;
    memset(&send_msg, 0, sizeof(mach_request_msg_t));
    
    send_msg.header.msgh_bits = MACH_MSGH_BITS(MACH_MSG_TYPE_COPY_SEND, MACH_MSG_TYPE_MAKE_SEND);
    send_msg.header.msgh_size = sizeof(send_msg);
    send_msg.header.msgh_remote_port = server_port;
    send_msg.header.msgh_local_port = client_port;
    send_msg.header.msgh_id = mach_message_request_image_id;
    
    strncpy(send_msg.request, name.UTF8String, PATH_MAX);
    
    ret = mach_msg(&send_msg.header, MACH_SEND_MSG, send_msg.header.msgh_size, 0, MACH_PORT_NULL, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
    if (ret != MACH_MSG_SUCCESS) {
        return;
    }
    
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_MACH_RECV, client_port, 0, dispatch_get_main_queue());
    dispatch_source_set_event_handler(source, ^{
        mach_response_msg_t *request = (mach_response_msg_t *)calloc(1, 2048);
        request->header.msgh_size = 2048;
        
        while (1) {
            request->header.msgh_bits = 0;
            request->header.msgh_local_port = client_port;
            request->header.msgh_remote_port = MACH_PORT_NULL;
            request->header.msgh_id = 0;
            
            mach_msg_option_t options = (MACH_RCV_MSG | MACH_RCV_LARGE | MACH_RCV_TRAILER_TYPE(MACH_MSG_TRAILER_FORMAT_0) | MACH_RCV_TRAILER_ELEMENTS(MACH_RCV_TRAILER_AV));
            kern_return_t ret = mach_msg(&request->header, options, 0, request->header.msgh_size, client_port, 0, MACH_PORT_NULL);
            if (ret == MACH_MSG_SUCCESS) {
                break;
            }
            if (ret == MACH_RCV_TOO_LARGE) {
                return;
            }
            
            uint32_t size = round_msg(request->header.msgh_size + MAX_TRAILER_SIZE);
            request = realloc(request, size);
            request->header.msgh_size = size;
        }
        
        __unused dispatch_source_t strongSource = self.sourceQueue[name];
        [self.sourceQueue removeObjectForKey:name];
        
        NSData *data = [NSData dataWithBytes:request->data length:request->data_size];
        if (data == nil) {
            return;
        }
        
        NSImage *image = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:NULL];
        if (image == nil) {
            return;
        }
        
        completion(image);
    });
    dispatch_resume(source);
    
    [self.sourceQueue setObject:source forKey:name];
}

@end
