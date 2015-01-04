//
//  CecManager.h
//  HDMI Volume Control
//
//  Created by Ryan Sullivan on 1/3/15.
//  Copyright (c) 2015 Pickled Code. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CECAPI : NSObject

-(bool)initialize:(const char*)device;

-(void)volumeUp;
-(void)volumeDown;

@end
