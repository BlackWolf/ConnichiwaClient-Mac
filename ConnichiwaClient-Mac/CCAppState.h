//
//  CCAppState.h
//  ConnichiwaClient-Mac
//
//  Created by Mario Schreiner on 06/07/14.
//  Copyright (c) 2014 Mario Schreiner. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CCAppState <NSObject>

/**
 *  The unique identifier of this device that is used amongst all the different parts of Connichiwa
 */
@property (readonly) NSString *identifier;

@property (readonly) NSString *deviceName;

/**
 *  Determines if this device is currently running as a remote device for another Connichiwa device.
 *
 *  @return true if the device is currently used as a remote device, otherwise false
 */
- (BOOL)isRemote;

/**
 *  Determines if this device can still become a remote device. This is, for example, not possible if this device is already a remote device or if remote devices are connected to it.
 *
 *  @return true if the device can still become a remote device, otherwise false
 */
- (BOOL)canBecomeRemote;

@end
