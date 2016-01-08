//
//  Shared.h
//  ipc
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import <Foundation/Foundation.h>

enum connection_type {
    connection_type_ns_xpc_connection = 0,
    connection_type_xpc = 1,
    connection_type_ns_port_message = 2,
    connection_type_cf_message_port_sync = 3,
    connection_type_cf_message_port_async = 4,
    connection_type_mach_mig = 5,
    connection_type_mach = 6,
    connection_type_unix_socket = 7,
};
typedef enum connection_type connection_type;

#define CONNECTION_TYPE connection_type_xpc

static NSString *ServerClasses[] = {
    @"ServerNSXPCConnection",
    @"ServerXPC",
};

static NSString *ClientClasses[] = {
    @"ClientNSXPCConnection",
    @"ClientXPC",
};
