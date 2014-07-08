//
//  CCBluetoothTransferManagerProtocol.h
//  ConnichiwaClient-Mac
//
//  Created by Mario Schreiner on 08/07/14.
//  Copyright (c) 2014 Mario Schreiner. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CCBluetoothTransferManagerDelegate <NSObject>

- (void)didReceiveMessage:(NSData *)data fromCentral:(CBCentral *)central withCharacteristic:(CBCharacteristic *)characteristic lastWriteRequest:(CBATTRequest *)request;

@end
