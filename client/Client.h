//
//  Client.h
//  ipc
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Client <NSObject>

- (void)requestImage:(NSString *)name completion:(void(^)(NSImage *image, NSError *error))completion;

@end

static NSString * const ClientErrorDomain = @"ClientErrorDomain";
static const NSInteger ClientErrorCodeUnknown = 0;
