//
//  ServerMIG.m
//  ipc
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import "ServerMIG.h"

#import <mach/bootstrap.h>
#import <pthread/pthread.h>
#import <servers/bootstrap.h>

#import "SharedMIG.h"
#import "shared_migServer.h"

@interface ServerMIG ()

@property (assign, nonatomic) mach_port_t port;
@property (strong, nonatomic) dispatch_queue_t server_queue;

@end

@implementation ServerMIG

@synthesize requestHandler = _requestHandler;

/*
    this is slightly unfortunate but the MIG `request_image` doesn't pass us anything that we could
    use to get our server instance (such as a pointer to some context info).
    however, since we are given the server mach port we can keep a map of ports to instance so that
    we can retrieve our server (and invoke its `requestHandler`) from the MIG function.
 */
static NSMapTable *_port_to_server_map = NULL;
static pthread_rwlock_t _port_to_server_rwlock = PTHREAD_RWLOCK_INITIALIZER;

static void __attribute__((constructor)) _map_initializer(void)
{
    _port_to_server_map = [NSMapTable strongToWeakObjectsMapTable];
}

- (void)dealloc
{
    pthread_rwlock_wrlock(&_port_to_server_rwlock);
    [_port_to_server_map removeObjectForKey:@(_port)];
    pthread_rwlock_unlock(&_port_to_server_rwlock);
}

- (void)startServer
{
    mach_port_t port;
    kern_return_t ret = bootstrap_check_in(bootstrap_port, mig_mach_service_name, &port);
    if (ret != BOOTSTRAP_SUCCESS) {
        return;
    }
    
    self.port = port;

    pthread_rwlock_wrlock(&_port_to_server_rwlock);
    [_port_to_server_map setObject:self forKey:@(port)];
    pthread_rwlock_unlock(&_port_to_server_rwlock);
    
    dispatch_queue_t server_queue = dispatch_queue_create("mig-server", DISPATCH_QUEUE_SERIAL);
    self.server_queue = server_queue;

    /*
        this is using implementation details of MIG, but I guess that's what MIG is about :-/
        
        Looking at the MIG generated code, we can see that it send the following request from the client:
        
         typedef struct {
             mach_msg_header_t Head;
             NDR_record_t NDR;
             request_input_t request;
         } Request;
     
        Our max size thus needs to be the size of this struct. It's worth noting that the receiving side will
        have a trailer appended to the message but `mach_msg_server` takes care of adding `MAX_TRAILER_SIZE`
        to our max_size parameter before passing it to `mach_msg`. We could be paranoid and add `MAX_TRAILER_SIZE`.
     */
    static mach_msg_size_t max_size = sizeof(mach_msg_header_t) + sizeof(NDR_record_t) + sizeof(request_input_t);

    // `mach_msg_server` blocks, looping and receiving new messages, so run it on a background queue
    dispatch_async(server_queue, ^{
        mach_msg_server(shared_mig_server, max_size, port, MACH_MSG_TIMEOUT_NONE);
    });
}

kern_return_t request_image(mach_port_t server_port, request_input_t request, vm_offset_t *data, mach_msg_type_number_t *data_len)
{
    // retrieve the server instance for this port
    pthread_rwlock_rdlock(&_port_to_server_rwlock);
    ServerMIG *server = [_port_to_server_map objectForKey:@(server_port)];
    pthread_rwlock_unlock(&_port_to_server_rwlock);

    if (server == NULL) {
        return -1;
    }

    NSString *filename = [NSString stringWithUTF8String:request];
    if (filename == nil) {
        return -1;
    }

    NSImage *image = server.requestHandler(server, filename);
    if (image == nil) {
        return -1;
    }
    
    NSData *imageData = [NSKeyedArchiver archivedDataWithRootObject:image];
    if (imageData == nil) {
        return -1;
    }
    
    *data = (vm_offset_t)imageData.bytes;
    *data_len = (mach_msg_type_number_t)imageData.length;
    
    return MACH_MSG_SUCCESS;
}

@end
