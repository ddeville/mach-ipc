//
//  SharedCFMessagePortAsync.h
//  ipc
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>

static CFStringRef const MessagePortAsyncServiceName = CFSTR("com.ddeville.ipc");

static uint32_t MessagePortAsyncRequestImageId = 1;
static uint32_t MessagePortAsyncResponseImageId = 2;
