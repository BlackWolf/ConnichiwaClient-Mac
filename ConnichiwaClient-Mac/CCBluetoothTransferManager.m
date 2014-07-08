//
//  CCBluetoothTransferManager.m
//  ConnichiwaClient-Mac
//
//  Created by Mario Schreiner on 08/07/14.
//  Copyright (c) 2014 Mario Schreiner. All rights reserved.
//

#import "CCBluetoothTransferManager.h"
#import "CCDebug.h"



@interface CCBluetoothTransferCentralKey : NSObject <NSCopying>

@property (readwrite, strong) CBCentral *central;
@property (readwrite, strong) CBCharacteristic *characteristic;

@end



@implementation CCBluetoothTransferCentralKey


- (instancetype)init
{
    [NSException raise:@"Not allowed" format:@"Cant create TransferCentralKey without a central and characteristic"];
    
    return nil;
}


- (instancetype)initWithCentral:(CBCentral *)central characteristic:(CBCharacteristic *)characteristic
{
    self = [super init];
    
    self.central = central;
    self.characteristic = characteristic;
    
    return self;
}


- (BOOL)isEqual:(id)object
{
    if (object == self) return YES;
    if ([object isKindOfClass:[CCBluetoothTransferCentralKey class]] == NO) return NO;
    
    return [self isEqualToCCBluetoothTransferCentralKey:object];
}


- (BOOL)isEqualToCCBluetoothTransferCentralKey:(CCBluetoothTransferCentralKey *)otherKey
{
    return ([otherKey.central isEqual:self.central] && [otherKey.characteristic isEqual:self.characteristic]);
}


- (NSUInteger)hash
{
    NSUInteger prime = 31;
    NSUInteger result = 1;
    
    result = prime * result + [self.central hash];
    result = prime * result + [self.characteristic hash];
    
    return result;
}


- (id)copyWithZone:(NSZone *)zone
{
    return [[CCBluetoothTransferCentralKey alloc] initWithCentral:self.central characteristic:self.characteristic];
}

@end



@interface CCBluetoothTransferManager ()

@property (readwrite, strong) CBPeripheralManager *peripheralManager;
@property (readwrite, strong) NSMutableDictionary *centralSends;
@property (readwrite, strong) NSMutableArray *centralEOMSends;
@property (readwrite, strong) NSMutableDictionary *centralReceives;

@end



@implementation CCBluetoothTransferManager


- (instancetype)initWithPeripheralManager:(CBPeripheralManager *)peripheralManager
{
    self = [super init];
    
    self.peripheralManager = peripheralManager;
    self.centralSends = [NSMutableDictionary dictionary];
    self.centralEOMSends = [NSMutableArray array];
    self.centralReceives = [NSMutableDictionary dictionary];
    
    return self;
}


#pragma mark Peripheral -> Central


- (void)sendData:(NSData *)data toCentral:(CBCentral *)central withCharacteristic:(CBMutableCharacteristic *)characteristic
{
    BTLog(3, @"Preparing to send data to central %@: %@", [central.identifier UUIDString], [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    CCBluetoothTransferCentralKey *key = [[CCBluetoothTransferCentralKey alloc] initWithCentral:central characteristic:characteristic];
    [self.centralSends setObject:[data mutableCopy] forKey:key];
    [self _sendNextChunkToCentral:key];
}


- (void)_sendNextChunkToCentral:(CCBluetoothTransferCentralKey *)key
{
    NSMutableData *remainingData = [self.centralSends objectForKey:key];
    
    if (remainingData == nil)
    {
        ErrLog(@"Tried to send data to a central where no data was left to send - this should never happen, something went majorly wrong here");
        return;
    }
    
    NSUInteger bytesToSend = 20;
    if ([remainingData length] < bytesToSend) bytesToSend = [remainingData length];
    
    NSData *chunk = [NSData dataWithBytes:[remainingData bytes] length:bytesToSend];
//    BOOL didSend = [self.peripheralManager updateValue:chunk forCharacteristic:(CBMutableCharacteristic *)key.characteristic onSubscribedCentrals:@[key.central]];
    BOOL didSend = [self.peripheralManager updateValue:chunk forCharacteristic:(CBMutableCharacteristic *)key.characteristic onSubscribedCentrals:nil];
    
    //
    // TODO
    // There is a bug in OS X where sending to a specific central crashes BTLE - maybe we can figure out a way around it? For now, broadcasting should work, though
    //
    
    //If there was still room in the queue (didSend==YES), we can go on sending
    //If the queue is full we wait for the peripheralManagerIsReadyToSend callback, which will call this method again
    if (didSend)
    {
        BTLog(4, @"Did send chunk of data to central %@: %@", [key.central.identifier UUIDString], [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding]);
        //Remove the chunk we just sent from the remaining data
        NSRange range = NSMakeRange(0, bytesToSend);
        [remainingData replaceBytesInRange:range withBytes:NULL length:0]; //note: this will update the nsdata entry in centralSends as well
        
        if ([remainingData length] == 0)
        {
            //We sent all regular data, we just need to sent the EOM and we're done
            [self.centralSends removeObjectForKey:key];
            [self.centralEOMSends addObject:key];
            
            [self _sendEOMToCentral:key];
        }
        else
        {
            //Still data to send, so let's go on
            [self _sendNextChunkToCentral:key];
        }
    }
    else
    {
        BTLog(4, @"Tried to send chunk of data to central %@, but queue was full", [key.central.identifier UUIDString]);
    }
}


- (void)_sendEOMToCentral:(CCBluetoothTransferCentralKey *)key
{
    if ([self.centralEOMSends containsObject:key] == NO)
    {
        ErrLog(@"Tried to send EOM that either received no data or already got the EOM - this should never happen, something went majorly wrong here");
        return;
    }
    
    NSData *eomData = [@"EOM" dataUsingEncoding:NSUTF8StringEncoding];
//    BOOL didSend = [self.peripheralManager updateValue:eomData forCharacteristic:key.characteristic onSubscribedCentrals:@[key.central]];
    BOOL didSend = [self.peripheralManager updateValue:eomData forCharacteristic:(CBMutableCharacteristic *)key.characteristic onSubscribedCentrals:nil];
    
    //
    // TODO
    // There is a bug in OS X where sending to a specific central crashes BTLE - maybe we can figure out a way around it? For now, broadcasting should work, though
    //
    
    //If the EOM was sent we are done with this central, otherwise we need for peripheralManagerIsReadyToSend to call this method
    if (didSend)
    {
        BTLog(4, @"Did send EOM to central %@, message complete.", [key.central.identifier UUIDString]);
        [self.centralEOMSends removeObject:key];
        //TODO send something to delegate I guess, we completed the send
    }
    else
    {
        BTLog(4, @"Tried to send EOM to central %@, but queue was full", [key.central.identifier UUIDString]);
    }
}


- (void)canContinueSendingToCentrals
{
    //First, see if we have EOMs that need to be send and complete those
    if ([self.centralEOMSends count] > 0)
    {
        [self _sendEOMToCentral:[self.centralEOMSends objectAtIndex:0]];
        return;
    }
    
    //If we have no outstanding EOMs, continue sending regular message data if necessary
    if ([self.centralSends count] > 0)
    {
        [self _sendNextChunkToCentral:[[self.centralSends allKeys] objectAtIndex:0]];
        return;
    }
}


#pragma mark Central -> Peripheral


- (void)receivedDataFromCentral:(CBATTRequest *)writeRequest
{
    NSData *chunk = writeRequest.value;
    CBCentral *central = writeRequest.central;
    CBCharacteristic *characteristic = writeRequest.characteristic;
    
    CCBluetoothTransferCentralKey *key = [[CCBluetoothTransferCentralKey alloc] initWithCentral:central characteristic:characteristic];
    NSMutableData *existingData = [self.centralReceives objectForKey:key];
    
    if ([[[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding] isEqualToString:@"EOM"])
    {
        BTLog(4, @"Received EOM from central %@, message complete.", [central.identifier UUIDString]);
        [self.centralReceives removeObjectForKey:key];
        
        if ([self.delegate respondsToSelector:@selector(didReceiveMessage:fromCentral:withCharacteristic:lastWriteRequest:)])
        {
            [self.delegate didReceiveMessage:existingData fromCentral:central withCharacteristic:characteristic lastWriteRequest:writeRequest];
        }
        return;
    }
    
    BTLog(4, @"Received chunk of data from central %@: %@", [central.identifier UUIDString], [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding]);
    
    if (existingData == nil)
    {
        [self.centralReceives setObject:[chunk mutableCopy] forKey:key];
    }
    else
    {
        [existingData appendData:chunk];
    }
}


@end
