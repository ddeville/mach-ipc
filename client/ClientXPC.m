//
//  ClientXPC.m
//  ipc
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import "ClientXPC.h"

#import "SharedXPC.h"

@implementation ClientXPC

- (void)requestImage:(NSString *)name completion:(void(^)(NSImage *image))completion
{
    xpc_connection_t connection = xpc_connection_create_mach_service(xpc_mach_service_name, dispatch_get_main_queue(), 0);
    xpc_connection_set_event_handler(connection, ^(xpc_object_t object) {});

    xpc_connection_resume(connection);

    xpc_object_t request = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_string(request, xpc_request_filename_key, name.UTF8String);

    xpc_connection_send_message_with_reply(connection, request, dispatch_get_main_queue(), ^(xpc_object_t object) {
        if (xpc_get_type(object) != XPC_TYPE_DICTIONARY) {
            return;
        }

        size_t length = 0;
        const void *bytes = xpc_dictionary_get_data(object, xpc_response_image_key, &length);
        if (bytes == NULL) {
            return;
        }

        NSData *imageData = [NSData dataWithBytes:bytes length:length];
        if (imageData == nil) {
            return;
        }

        NSImage *image = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:imageData error:NULL];
        if (image == nil) {
            return;
        }

        completion(image);
    });
}

@end
