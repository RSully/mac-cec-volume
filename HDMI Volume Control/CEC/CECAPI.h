//
//  CecManager.h
//  HDMI Volume Control
//
//  Created by Ryan Sullivan on 1/3/15.
//  Copyright (c) 2015 Pickled Code. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CECAPI : NSObject

-(BOOL)open:(const char *)devicePath;
-(const char *)getDefaultDevicePath;

/**
 * Manual key down/up audio commands
 */
-(BOOL)volumeUpKeydown;
-(BOOL)volumeDownKeydown;
-(BOOL)audioKeyup;

/**
 * Normal audio keypresses (auto-release)
 */
-(BOOL)volumeUpKeypress;
-(BOOL)volumeDownKeypress;

/**
 * Toggle mute state
 */
-(BOOL)toggleMuteKeypress;

-(void)debug;

@end
