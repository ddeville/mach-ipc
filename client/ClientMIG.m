//
//  ClientMIG.m
//  ipc
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import "ClientMIG.h"

#import <servers/bootstrap.h>

#import "SharedMIG.h"
#import "shared_mig.h"

@implementation ClientMIG

- (void)requestImage:(NSString *)name completion:(void(^)(NSImage *image, NSError *error))completion
{
    mach_port_t server_port;
    kern_return_t looked_up = bootstrap_look_up(bootstrap_port, mig_mach_service_name, &server_port);
    if (looked_up != BOOTSTRAP_SUCCESS) {
        completeWithDefaultError(completion);
        return;
    }
    
    vm_offset_t data;
    mach_msg_type_number_t data_len;
    kern_return_t ret = request_image(server_port, (char *)name.UTF8String, &data, &data_len);
    if (ret != MACH_MSG_SUCCESS) {
        completeWithDefaultError(completion);
        return;
    }
    
    NSData *imageData = [NSData dataWithBytes:(const void *)data length:(NSUInteger)data_len];
    vm_deallocate(mach_task_self(), data, data_len);
    if (imageData == nil) {
        completeWithDefaultError(completion);
        return;
    }
    
    NSImage *image = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:imageData error:NULL];
    if (image == nil) {
        completeWithDefaultError(completion);
        return;
    }
    
    completion(image, nil);
}

@end
