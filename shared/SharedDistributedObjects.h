//
//  SharedDistributedObjects.h
//  ipc
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import <Cocoa/Cocoa.h>

static NSString * const DistributedObjectsName = @"com.ddeville.ipc";

@protocol ConnectionProtocol <NSObject>

- (NSData *)requestImage:(NSString *)request;

@end
