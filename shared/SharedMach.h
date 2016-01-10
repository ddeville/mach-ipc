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

// the request message as seen by the sender
struct mach_request_msg {
    mach_msg_header_t header;
    char filename[PATH_MAX];
};
typedef struct mach_request_msg mach_request_msg_t;

// the request message as seen by the receiver (additional trailer)
struct mach_request_receiver_msg {
    mach_msg_header_t header;
    char filename[PATH_MAX];
    mach_msg_trailer_t trailer;
};
typedef struct mach_request_receiver_msg mach_request_receiver_msg_t;

// the response message as seen by the sender
struct mach_response_msg {
    mach_msg_header_t header;
    mach_msg_body_t body;
    mach_msg_ool_descriptor_t data;
    mach_msg_type_number_t data_count;
};
typedef struct mach_response_msg mach_response_msg_t;

// the response message as seen by the sender (additional trailer)
struct mach_response_receiver_msg {
    mach_msg_header_t header;
    mach_msg_body_t body;
    mach_msg_ool_descriptor_t data;
    mach_msg_type_number_t data_count;
    mach_msg_trailer_t trailer;
};
typedef struct mach_response_receiver_msg mach_response_receiver_msg_t;
