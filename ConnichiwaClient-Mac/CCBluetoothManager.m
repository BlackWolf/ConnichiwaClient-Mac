//
//  CCBluetoothManager.m
//  ConnichiwaClient-Mac
//
//  Created by Mario Schreiner on 06/07/14.
//  Copyright (c) 2014 Mario Schreiner. All rights reserved.
//

#import "CCBluetoothManager.h"
#import "CCUtil.h"
#import "CCDebug.h"



@interface CCBluetoothManager () <CBPeripheralManagerDelegate, CBPeripheralDelegate>

@property (readwrite, weak) id<CCAppState> appState;

/**
 *  The CBPeripheralManager instance used by this manager to make this device a BTLE Peripheral
 */
@property (readwrite, strong) CBPeripheralManager *peripheralManager;

/**
 *  The Connichiwa service advertised by this device
 */
@property (readwrite, strong) CBMutableService *advertisedService;

/**
 *  The initial characteristic advertised by this device. Subscribing to this characteristic will trigger this device to send its initial device data to the other device.
 */
@property (readwrite, strong) CBMutableCharacteristic *advertisedInitialCharacteristic;

/**
 *  The IP characteristic advertised by this device. This is a writable characteristic that other devices can write data to, but only valid IPs will be accepted. Writing IPs to this characteristic will trigger this device to test if that IP leads to a valid Connichiwa web server. If so, this device will connect to it and effecitvely become a remote device.
 */
@property (readwrite, strong) CBMutableCharacteristic *advertisedIPCharacteristic;

/**
 *  Determines if the Connichiwa service was already added to the CBPeripheralManager and is advertised to other devices
 */
@property (readwrite) BOOL didAddService;

/**
 *  Determines if startAdvertising was called but we didn't start advertising yet
 */
@property (readwrite) BOOL wantsToStartAdvertising;

/**
 *  Sends our initial device data to the given CBCentral via the initial characteristic. This method should be triggered after a central subscribed to our initial characteristic.
 *
 *  @param central The CBCentral that subscribed to the initial characteristic and should receive the data
 */
- (void)_sendInitialToCentral:(CBCentral *)central;

@end



/**
 *  The UUID used to advertise the Connichiwa BT Service.
 *  Must be the same on all devices.
 */
NSString *const BLUETOOTH_SERVICE_UUID = @"AE11E524-2034-40F8-96D3-5E1028526348";

/**
 *  The UUID used to advertise the Connichiwa BT Characteristic for the data transfer of initial device data from peripheral to central.
 *  Must be the same on all devices.
 */
NSString *const BLUETOOTH_INITIAL_CHARACTERISTIC_UUID = @"22F445BE-F162-4F9B-804C-1636D7A24462";

/**
 *  The UUID used to advertise the Connichiwa BT Characteristic for the transfer of the network interface IPs from central to peripheral.
 *  Must be the same on all devices.
 */
NSString *const BLUETOOTH_IP_CHARACTERISTIC_UUID = @"8F627B80-B760-440C-880D-EFE99CFB6436";

/**
 *  When checking a URL for a Connichiwa webserver, this is the amount of seconds after which we consider the request failed
 */
double const URL_CHECK_TIMEOUT = 2.0;



@implementation CCBluetoothManager


- (instancetype)initWithApplicationState:(id<CCAppState>)appState
{
    self = [super init];
    
    self.appState = appState;
    
    dispatch_queue_t peripheralQueue = dispatch_queue_create("connichiwaperipheralqueue", DISPATCH_QUEUE_SERIAL);
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:peripheralQueue];
    
    //When a central subscribes to the initial characteristic, we will sent it our initial device data, including our unique identifier
    self.advertisedInitialCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:BLUETOOTH_INITIAL_CHARACTERISTIC_UUID]
                                                                              properties:CBCharacteristicPropertyNotify
                                                                                   value:nil
                                                                             permissions:CBAttributePermissionsReadable];
    
    //A central can subscribe to the IP characteristic when it wants to use our device as a remote device
    //The characteristic is writeable and allows the central to send us its
    self.advertisedIPCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:BLUETOOTH_IP_CHARACTERISTIC_UUID]
                                                                         properties:CBCharacteristicPropertyWrite
                                                                              value:nil
                                                                        permissions:CBAttributePermissionsWriteable];
    
    self.advertisedService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:BLUETOOTH_SERVICE_UUID] primary:YES];
//    self.advertisedService.characteristics = @[ self.advertisedInitialCharacteristic ];
    self.advertisedService.characteristics = @[ self.advertisedInitialCharacteristic, self.advertisedIPCharacteristic ];
    
    self.didAddService = NO;
    self.wantsToStartAdvertising = NO;
    
    return self;
}


- (void)startAdvertising
{
    BTLog(3, @"Trying to advertise to other BT devices");
    if (self.peripheralManager.state == CBPeripheralManagerStatePoweredOn)
    {
        [self _doStartAdvertising];
    }
    else
    {
        self.wantsToStartAdvertising = YES;
    }
}


- (void)stopAdvertising
{
    BTLog(1, @"Stop advertising to other BT devices");
    
    self.wantsToStartAdvertising = NO;
    [self.peripheralManager stopAdvertising];
}


- (BOOL)isAdvertising
{
    return self.peripheralManager != nil && self.peripheralManager.isAdvertising;
}


- (void)_doStartAdvertising
{
    if ([self isAdvertising]) return;
    
    BTLog(1, @"Starting to advertise to other BT devices with identifier %@", self.appState.identifier);
    
    [self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:BLUETOOTH_SERVICE_UUID]] }];
}


- (void)_sendInitialToCentral:(CBCentral *)central
{
    BTLog(3, @"Preparing to send initial data to %@", central);
    
    NSDictionary *sendDictionary = @{ @"identifier": self.appState.identifier, @"name": self.appState.deviceName };
    NSData *initialData = [NSJSONSerialization dataWithJSONObject:sendDictionary options:NSJSONWritingPrettyPrinted error:nil];
//    initialData = [@"rofl" dataUsingEncoding:NSUTF8StringEncoding];
//    BOOL didSend = [self.peripheralManager updateValue:initialData forCharacteristic:self.advertisedInitialCharacteristic onSubscribedCentrals:@[central]];
    BOOL didSend = [self.peripheralManager updateValue:initialData forCharacteristic:self.advertisedInitialCharacteristic onSubscribedCentrals:nil];
    
    if (didSend == NO)
    {
        ErrLog(@"Unable to send initial data to %@", central);
    }
    else
    {
        BTLog(3, @"Totally sent %@", sendDictionary);
    }
}


#pragma mark CBPeripheralManagerDelegate


/**
 *  Called when the state of the CBPeripheralManager was updated. Mainly used to to detect when the PeripheralManager was powered on and is ready to be used.
 *
 *  @param peripheralManager The CBPeripheralManager whose state changed
 */
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheralManager
{
    if (peripheralManager.state == CBCentralManagerStatePoweredOn)
    {
        //Add the Connichiwa service to the peripheral. When the service was added, XXX will be called
        if (self.didAddService == NO)
        {
            self.didAddService = YES;
            [self.peripheralManager addService:self.advertisedService];
        }
    }
    
    [CCDebug executeInDebug:^{
        NSString *stateString;
        switch (peripheralManager.state)
        {
            case CBPeripheralManagerStatePoweredOn: stateString = @"PoweredOn"; break;
            case CBPeripheralManagerStateResetting: stateString = @"Resetting"; break;
            case CBPeripheralManagerStateUnsupported: stateString = @"Unsupported"; break;
            case CBPeripheralManagerStateUnauthorized: stateString = @"Unauthorized"; break;
            case CBPeripheralManagerStatePoweredOff: stateString = @"PoweredOff"; break;
            default: stateString = @"Unknown"; break;
        }
        BTLog(1, @"Peripheral Manager state changed to %@", stateString);
    }];
}


/**
 *  Called after the peripheral manager's addService: was called and the service was added to the peripheral and is now published. If startAdvertising was called before this callback arrives, we will repeat the call.
 *
 *  @param peripheral The PeripheralManager the service was added to
 *  @param service    The service that was added
 *  @param error      An error if something went wrong or nil if the service was added successfully
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    if (error != nil)
    {
        self.didAddService = NO;
        ErrLog(@"Could not advertise Connichiwa service. Error: %@", error);
        return;
    }
    
    if (self.wantsToStartAdvertising == YES)
    {
        [self startAdvertising];
    }
}


/**
 *  Called whenever we received a write request for a characteristic. This is called when a central sends us data via a writable characteristic. The sent data is stored in a request's value property. A call to this method can contain multiple write requests, but we should only send a single response. Responding will trigger the CBPeripheral's peripheral:didWriteValueForCharacteristic:error: method on the sending device.
 *
 *  @param peripheral The CBPeripheralManager that received the request
 *  @param requests   An array of one or more write requests
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    BOOL requestsValid = NO;
    for (CBATTRequest *writeRequest in requests)
    {
        BTLog(4, @"Did receive IP from another device: %@", [[NSString alloc] initWithData:writeRequest.value encoding:NSUTF8StringEncoding]);
        
        NSDictionary *retrievedData = [CCUtil dictionaryFromJSONData:writeRequest.value];
        
        if (retrievedData[@"ip"] == nil)
        {
            ErrLog(@"Error in the retrieved IP");
            continue;
        }
        
        //If we can't become a remote anyway, we reject any IPs we receive
        if ([self.appState canBecomeRemote] == NO) continue;
        
        NSHTTPURLResponse *response = nil;
        NSError *error = nil;
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/check", retrievedData[@"ip"]]];
        NSMutableURLRequest *request = [NSMutableURLRequest
                                        requestWithURL:url
                                        cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                        timeoutInterval:URL_CHECK_TIMEOUT];
        [request setHTTPMethod:@"HEAD"];
        
        BTLog(3, @"Checking IP %@ for validity", url);
        [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if ([response statusCode] == 200)
        {
            //We found the correct IP!
            BTLog(3, @"%@ is a valid URL", url);
            if ([self.delegate respondsToSelector:@selector(didReceiveDeviceURL:)])
            {
                [self.delegate didReceiveDeviceURL:[url URLByDeletingLastPathComponent]]; //remove /check
            }
            requestsValid = YES;
        }
    }
    
    //We exploit the write request responses here to indicate if the IP(s) received worked or not
    if (requestsValid) [self.peripheralManager respondToRequest:[requests objectAtIndex:0] withResult:CBATTErrorSuccess];
    else [self.peripheralManager respondToRequest:[requests objectAtIndex:0] withResult:CBATTErrorAttributeNotFound];
}


/**
 *  Called when a remote central subscribed to one of our notifyable characteristics via setNotify:forCharacteristic:
 *
 *  @param peripheral     The CBPeripheralManager that is responsible for the characteristic
 *  @param central        The CBCentral that subscribed to the characteristic
 *  @param characteristic The characteristic that was subscribed to
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    if (characteristic == self.advertisedInitialCharacteristic)
    {
        BTLog(3, @"Another device subscribed to our initial characteristic");
        [self _sendInitialToCentral:central];
    }
}


/**
 *  Called when a remote central cancelled the subscription to a notifyable characteristic of ours. Can be called because of a manual unsubscribe, but will also be called if the device unsubscribed because it disconnected.
 *
 *  @param peripheral     The CBPeripheralManager
 *  @param central        The CBCentral that unsubscribed
 *  @param characteristic The characteristic that was unsubscribed
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    if (characteristic == self.advertisedInitialCharacteristic)
    {
        BTLog(3, @"Another device unsubscribed from our initial characteristic");
    }
}


/**
 *  Called after _doStartAdvertising was called and the advertising was started
 *
 *  @param peripheral The PeripheralManager advertising
 *  @param error      An error describing the reason for failure, or nil if no error occured and advertisement started
 */
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    BTLog(2, @"Did start advertising to other BT devices");
    
    if (error == nil)
    {
        if ([self.delegate respondsToSelector:@selector(didStartAdvertisingWithIdentifier:)])
        {
            [self.delegate didStartAdvertisingWithIdentifier:self.appState.identifier];
        }
    }
}


@end
