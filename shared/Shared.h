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
    connection_type_distributed_objects = 2,
    connection_type_ns_port_message = 3,
    connection_type_cf_message_port = 4,
    connection_type_mach_mig = 5,
    connection_type_mach = 6,
    connection_type_unix_socket = 7,
};
typedef enum connection_type connection_type;

#define CONNECTION_TYPE connection_type_mach_mig

static NSString *ServerClasses[] = {
    @"ServerNSXPCConnection",
    @"ServerXPC",
    @"ServerDistributedObjects",
    @"ServerNSPortMessage",
    @"ServerCFMessagePort",
    @"ServerMIG",
    @"ServerMach",
    @"ServerSocket",
};

static NSString *ClientClasses[] = {
    @"ClientNSXPCConnection",
    @"ClientXPC",
    @"ClientDistributedObjects",
    @"ClientNSPortMessage",
    @"ClientCFMessagePort",
    @"ClientMIG",
    @"ClientMach",
    @"ClientSocket",
};
