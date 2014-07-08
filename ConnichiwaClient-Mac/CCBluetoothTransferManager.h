//
//  CCBluetoothTransferManager.h
//  ConnichiwaClient-Mac
//
//  Created by Mario Schreiner on 08/07/14.
//  Copyright (c) 2014 Mario Schreiner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>
#import "CCBluetoothTransferManagerDelegate.h"



@interface CCBluetoothTransferManager : NSObject

/**
 *  The delegate that receives events by this class
 */
@property (readwrite) id<CCBluetoothTransferManagerDelegate> delegate;

- (instancetype)initWithPeripheralManager:(CBPeripheralManager *)peripheralManager;
- (void)sendData:(NSData *)data toCentral:(CBCentral *)central withCharacteristic:(CBMutableCharacteristic *)characteristic;
- (void)receivedDataFromCentral:(CBATTRequest *)writeRequest;
- (void)canContinueSendingToCentrals;

@end
