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
@property int currentKey;
@property NSThread *thread;
@property NSTimer *timer;

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

    self.currentKey = 0;
    _thread =[[NSThread alloc] initWithTarget:self selector:@selector(runCEC) object:nil];
    [_thread start];
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
//        self.currentKey = 0;
//        [_cec audioKeyup];
        return;
    }

    switch (keyCode) {
        case NX_KEYTYPE_SOUND_DOWN:
            if (self.currentKey == 1) {
                [self sendStop];
            }
            self.currentKey = -1;
            break;
        case NX_KEYTYPE_SOUND_UP:
            if (self.currentKey == -1) {
                [self sendStop];
            }
            self.currentKey = 1;
            break;
        case NX_KEYTYPE_MUTE:
            self.currentKey = 0;
            [_cec toggleMuteKeypress];
            break;
    }

    [self resetClearTimer];
}

-(void)resetClearTimer {
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                  target:self
                                                selector:@selector(sendStop)
                                                userInfo:nil
                                                 repeats:NO];
}
-(void)sendStop {
    self.currentKey = 0;
    [_cec audioKeyup];
}

-(void)runCEC {
    while (1) {
        switch (self.currentKey) {
            case -1:
                [self.cec volumeDownKeydown];
                break;
            case 1:
                [self.cec volumeUpKeydown];
                break;
            case 0:
            default:
                break;
        }

        // 250 to 450 ms recommended
        [NSThread sleepForTimeInterval:.300];
    }
}

@end
