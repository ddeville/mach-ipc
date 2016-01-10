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
#import "shared_mig.h"

@interface ServerMIG ()

@property (assign, nonatomic) mach_port_t port;

@end

@implementation ServerMIG

@synthesize requestHandler = _requestHandler;

- (void)startServer
{
    mach_port_t port;
    kern_return_t ret = bootstrap_check_in(bootstrap_port, mig_mach_service_name, &port);
    if (ret != BOOTSTRAP_SUCCESS) {
        return;
    }
    
    self.port = port;
}

@end
