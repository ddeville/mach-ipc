//
//  SharedDistributedObjects.h
//  ipc
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import <Cocoa/Cocoa.h>

static NSString * const DistributedObjectsServiceName = @"com.ddeville.ipc.do";

@protocol ServerProtocol <NSObject>

// we could request the NSImage directly but DO doesn't seem to handle this case very well and complains by logging:
// "It does not make sense to draw an image when [NSGraphicsContext currentContext] is nil. This is a programming error."
- (NSData *)requestImage:(NSString *)request;

@end
