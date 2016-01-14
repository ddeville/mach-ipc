//
//  ServerApplication.m
//  Server
//
//  Created by Damien DeVille on 1/8/16.
//  Copyright © 2016 Damien DeVille. All rights reserved.
//

#import "ServerApplication.h"

#import "Shared.h"
#import "Server.h"
#import "ServerNSXPCConnection.h"

#define MANAGE_CLIENT   1

@interface ServerApplication (/* Bindings */)

@property (copy, nonatomic) NSAttributedString *log;

@property (strong, nonatomic) IBOutlet NSTextView *logTextView;

@end

@interface ServerApplication ()

@property (strong, nonatomic) NSArray<id <Server>> *servers;

@end

@implementation ServerApplication

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    __weak typeof(self) welf = self;
    NSImage *(^requestHandler)(id <Server>, NSString *) = ^NSImage *(id <Server> server, NSString *request) {
        __strong typeof(welf) strelf = welf;
        
        NSImage *image = [strelf _generateImage:request text:NSStringFromClass([server class])];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [strelf _appendToLog:[NSString stringWithFormat:@"Received request: \"%@\"", request] server:server];
            [strelf _appendToLog:[NSString stringWithFormat:@"Responding with image %@", image] server:server];
        });
        
        return image;
    };
    
    NSMutableArray *servers = [NSMutableArray array];
    
    for (int idx; idx < sizeof(ServerClasses) / sizeof(NSString *); idx++) {
        id <Server> server = [[NSClassFromString(ServerClasses[idx]) alloc] init];
        server.requestHandler = requestHandler;
        [server startServer];
        [servers addObject:server];
        [self _appendToLog:@"Started" server:server];
    }
    
    self.servers = servers;
    
#if MANAGE_CLIENT
    [self _launchClientIfNeeded];
#endif /* MANAGE_CLIENT */
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
#if MANAGE_CLIENT
    NSRunningApplication *client = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.ddeville.client"].firstObject;
    [client terminate];
#endif /* MANAGE_CLIENT */
}

- (void)_appendToLog:(NSString *)string server:(id <Server>)server
{
    if (string == nil) {
        return;
    }

    NSMutableString *log = [NSMutableString stringWithString:(self.log.string ?: @"")];
    if (log.length != 0) {
        [log appendString:@"\n\n"];
    }

    NSString *time = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle];
    [log appendFormat:@"%@ (%@): %@", time, NSStringFromClass([server class]), string];

    self.log = [[NSAttributedString alloc] initWithString:log attributes:nil];
    
    [self.logTextView scrollToEndOfDocument:nil];
}

- (void)_launchClientIfNeeded
{
    NSArray *clients = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.ddeville.client"];
    [clients makeObjectsPerformSelector:@selector(terminate)];
    
    NSString *clientPath = [[NSBundle mainBundle] pathForResource:@"client" ofType:@"app"];
    [[NSWorkspace sharedWorkspace] performSelector:@selector(launchApplication:) withObject:clientPath afterDelay:0.1];
    
    [self _appendToLog:@"Launched client" server:nil];
}

- (NSImage *)_generateImage:(NSString *)filename text:(NSString *)text
{
    NSImage *image = [[NSBundle mainBundle] imageForResource:filename];
    
    NSDictionary *attributes = @{
        NSForegroundColorAttributeName : [NSColor redColor],
        NSFontAttributeName: [NSFont boldSystemFontOfSize:50.0]
    };
    
    CGSize textSize = [text sizeWithAttributes:attributes];
    CGSize imageSize = image.size;
    
    CGPoint textPosition = CGPointMake(imageSize.width - textSize.width - 20.0, imageSize.height - textSize.height - 20.0);
    
    NSImage *updatedImage = [NSImage imageWithSize:imageSize flipped:YES drawingHandler:^BOOL(CGRect rect) {
        [image drawInRect:rect];
        [text drawAtPoint:textPosition withAttributes:attributes];
        return YES;
    }];
    
    return updatedImage;
}

@end
