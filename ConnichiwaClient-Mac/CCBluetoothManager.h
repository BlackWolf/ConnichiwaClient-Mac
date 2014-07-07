//
//  CCBluetoothManager.h
//  ConnichiwaClient-Mac
//
//  Created by Mario Schreiner on 06/07/14.
//  Copyright (c) 2014 Mario Schreiner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>
#import "CCBluetoothManagerDelegate.h"
#import "CCAppState.h"

@interface CCBluetoothManager : NSObject

/**
 *  The delegate that receives events by this class
 */
@property (readwrite) id<CCBluetoothManagerDelegate> delegate;

- (instancetype)initWithApplicationState:(id<CCAppState>)appState;
- (void)startAdvertising;
- (void)stopAdvertising;
- (BOOL)isAdvertising;

@end
