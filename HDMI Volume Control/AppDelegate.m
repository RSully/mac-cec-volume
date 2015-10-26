//
//  AppDelegate.m
//  HDMI Volume Control
//
//  Created by Ryan Sullivan on 1/3/15.
//  Copyright (c) 2015 Pickled Code. All rights reserved.
//

#import "AppDelegate.h"
#import "SPMediaKeyTap.h"
#import "CECAPI.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (strong) SPMediaKeyTap *keyTap;

@property CECAPI *cec;

@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    _cec = [CECAPI new];
    BOOL success = [_cec open:[_cec getDefaultDevicePath]];
    NSLog(@"Finished setting up CEC (%d)", success);

    _keyTap = [[SPMediaKeyTap alloc] initWithDelegate:self];
    
    if (![SPMediaKeyTap usesGlobalMediaKeyTap]) {
        NSLog(@"Media key monitoring disabled");
    }
    [self watchKeys:YES];
}

-(void)watchKeys:(bool)watch {
    if (!watch) {
        [_keyTap stopWatchingMediaKeys];
        return;
    }

    if ([SPMediaKeyTap usesGlobalMediaKeyTap]) {
        [_keyTap startWatchingMediaKeys];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [_keyTap stopWatchingMediaKeys];
}

-(IBAction)debug:(id)sender {
    [_cec debug];
}

-(void)mediaKeyTap:(SPMediaKeyTap *)keyTap receivedMediaKeyEvent:(NSEvent *)event {
    if (event.type != NSSystemDefined) {
        NSLog(@"Undefined event type");
        return;
    }
    if (event.subtype != SPSystemDefinedEventMediaKeys) {
        NSLog(@"Undefined event subtype");
        return;
    }


    int keyCode = ((event.data1 & 0xFFFF0000) >> 16);
    int keyFlags = (event.data1 & 0x0000FFFF);
    BOOL keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA;
//    int keyRepeat = (keyFlags & 0x1);

    if (!keyIsPressed) {
        [_cec audioKeyup];
        return;
    }

    switch (keyCode) {
        case NX_KEYTYPE_SOUND_DOWN:
            NSLog(@"Sound down");
            [_cec volumeDownKeydown];
            break;
        case NX_KEYTYPE_SOUND_UP:
            NSLog(@"Sound up");
            [_cec volumeUpKeydown];
            break;
        case NX_KEYTYPE_MUTE:
            NSLog(@"Mute");
            [_cec toggleMuteKeypress];
            break;
    }
}

@end
