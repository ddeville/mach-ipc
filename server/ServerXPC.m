//
//  ServerXPC.m
//  ipc
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import "ServerXPC.h"

#import "shared-xpc.h"

@interface ServerXPC ()

@property (strong, nonatomic) xpc_connection_t listener;

@end

@implementation ServerXPC

@synthesize requestHandler = _requestHandler;

- (void)startServer
{
    xpc_connection_t listener = xpc_connection_create_mach_service(xpc_mach_service_name, dispatch_get_main_queue(), XPC_CONNECTION_MACH_SERVICE_LISTENER);
    self.listener = listener;

    __weak ServerXPC *weakSelf = self;
    xpc_connection_set_event_handler(listener, ^(xpc_object_t object) {
        __strong ServerXPC *server = weakSelf;
        if (xpc_get_type(object) == XPC_TYPE_CONNECTION) {
            [server _acceptConnection:object];
        }
    });

    xpc_connection_resume(listener);
}

- (void)_acceptConnection:(xpc_object_t)connection
{
    xpc_connection_set_event_handler(connection, ^(xpc_object_t object) {
        if (xpc_get_type(object) != XPC_TYPE_DICTIONARY) {
            return;
        }
        
        const char *filename = xpc_dictionary_get_string(object, xpc_request_filename_key);
        xpc_object_t reply = xpc_dictionary_create_reply(object);
        xpc_connection_t client = xpc_dictionary_get_remote_connection(object);

        if (filename == NULL || reply == NULL || client == NULL) {
            return;
        }

        NSString *request = [NSString stringWithUTF8String:filename];
        NSImage *image = self.requestHandler(request);
        if (image == nil) {
            return;
        }

        NSData *imageData = [NSKeyedArchiver archivedDataWithRootObject:image];
        if (imageData == nil) {
            return;
        }

        xpc_dictionary_set_data(reply, xpc_response_image_key, imageData.bytes, imageData.length);
        xpc_connection_send_message(client, reply);

    });
    xpc_connection_resume(connection);
}

@end
