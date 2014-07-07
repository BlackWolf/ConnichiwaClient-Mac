//
//  CCBluetoothManagerDelegate.h
//  ConnichiwaClient-Mac
//
//  Created by Mario Schreiner on 06/07/14.
//  Copyright (c) 2014 Mario Schreiner. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CCBluetoothManagerDelegate <NSObject>

/**
 *  Called when the manager successfully started advertising this device to other BT device with the given identifier
 *
 *  @param identifier The identifier under wich we are advertised to other devices
 */
- (void)didStartAdvertisingWithIdentifier:(NSString *)identifier;

/**
 *  Caled when we received an URL that points to another Connichiwa web application
 *
 *  @param URL The URL of the remote Connichiwa web application
 */
- (void)didReceiveDeviceURL:(NSURL *)URL;

@end
