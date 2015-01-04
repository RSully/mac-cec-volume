//
//  AppDelegate.m
//  HDMI Volume Control
//
//  Created by Ryan Sullivan on 1/3/15.
//  Copyright (c) 2015 Pickled Code. All rights reserved.
//

#import "AppDelegate.h"
#import "SPMediaKeyTap.h"
#import "CecManager.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (strong) SPMediaKeyTap *keyTap;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    // todo
    [CecManager new];
    
    return;
    
    _keyTap = [[SPMediaKeyTap alloc] initWithDelegate:self];
    
    if ([SPMediaKeyTap usesGlobalMediaKeyTap]) {
        [_keyTap startWatchingMediaKeys];
    } else {
        NSLog(@"Media key monitoring disabled");
        abort();
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [_keyTap stopWatchingMediaKeys];
}

-(void)mediaKeyTap:(SPMediaKeyTap *)keyTap receivedMediaKeyEvent:(NSEvent *)event {
    NSAssert(event.type == NSSystemDefined, @"Event type undefined");
    NSAssert(event.subtype == SPSystemDefinedEventMediaKeys, @"Event subtype undefined");

    int keyCode = (([event data1] & 0xFFFF0000) >> 16);
    int keyFlags = ([event data1] & 0x0000FFFF);
    int keyRepeat = (keyFlags & 0x1);
    
    switch (keyCode) {
        case NX_KEYTYPE_SOUND_DOWN:
            NSLog(@"Sound down");
            break;
        case NX_KEYTYPE_SOUND_UP:
            NSLog(@"Sound up");
            break;
        case NX_KEYTYPE_MUTE:
            NSLog(@"Mute");
            break;
    }
}

@end
