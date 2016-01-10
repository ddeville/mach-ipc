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

@implementation ClientMach

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
}

@end
