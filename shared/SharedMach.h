//
//  SharedMach.h
//  ipc
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import <mach/mach.h>

static const char *mach_service_name = "com.ddeville.ipc";

static mach_msg_id_t mach_message_request_image_id = 1;

struct mach_request_msg {
    mach_msg_header_t header;
    char request[PATH_MAX];
};
typedef struct mach_request_msg mach_request_msg_t;

struct mach_response_msg {
    mach_msg_header_t header;
    size_t data_size;
    char data[16];
};
typedef struct mach_response_msg mach_response_msg_t;
