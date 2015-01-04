//
//  CecManager.h
//  HDMI Volume Control
//
//  Created by Ryan Sullivan on 1/3/15.
//  Copyright (c) 2015 Pickled Code. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CECAPI : NSObject

-(bool)open:(const char *)devicePath;
-(const char *)getDefaultDevicePath;

/**
 * Manual key down/up audio commands
 */
-(bool)volumeUpKeydown;
-(bool)volumeDownKeydown;
-(bool)audioKeyup;

/**
 * Normal audio keypresses (auto-release)
 */
-(bool)volumeUpKeypress;
-(bool)volumeDownKeypress;

/**
 * Toggle mute state
 */
-(bool)toggleMuteKeypress;

@end
