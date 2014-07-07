//
//  CCAppDelegate.m
//  ConnichiwaClient-Mac
//
//  Created by Mario Schreiner on 06/07/14.
//  Copyright (c) 2014 Mario Schreiner. All rights reserved.
//

#import "CCAppDelegate.h"
#import "CCAppState.h"
#import "CCBluetoothManager.h"
#import "CCBluetoothManagerDelegate.h"
#import "CCRemoteLibraryManager.h"
#import "CCRemoteLibManagerDelegate.h"


@interface CCAppDelegate () <CCAppState, CCBluetoothManagerDelegate, CCRemoteLibraryManagerDelegate, NSWindowDelegate>

/**
 *  The unique identifier of this device that is used amongst all the different parts of Connichiwa
 */
@property (readwrite, strong) NSString *identifier;
@property (readwrite, strong) NSString *deviceName;
@property (readwrite, strong) CCBluetoothManager *bluetoothManager;
@property (readwrite, strong) CCRemoteLibraryManager *remoteLibManager;

@end



@implementation CCAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
//    [self.window setDelegate:self];
//    [self.window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
//    [self.window toggleFullScreen:nil];
//    [self.window setCollectionBehavior:0];
    
    self.identifier = [[NSUUID UUID] UUIDString];
    self.deviceName = (__bridge NSString *)SCDynamicStoreCopyComputerName(NULL, NULL);
    
    self.remoteLibManager = [[CCRemoteLibraryManager alloc] initWithApplicationState:self];
    [self.remoteLibManager setWebView:self.webView];
    
    self.bluetoothManager = [[CCBluetoothManager alloc] initWithApplicationState:self];
    [self.bluetoothManager setDelegate:self];
    [self.bluetoothManager startAdvertising];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [self.bluetoothManager stopAdvertising];
}


- (void)windowDidEnterFullScreen:(NSNotification *)notification
{
    [NSApp setPresentationOptions:NSApplicationPresentationFullScreen];
}

/**
 *  See [CWBluetoothManagerDelegate didReceiveDeviceURL:]
 *
 *  @param URL See [CWBluetoothManagerDelegate didReceiveDeviceURL:]
 */
- (void)didReceiveDeviceURL:(NSURL *)URL;
{
    if ([self canBecomeRemote] == NO) return;
    
    //This is it, the moment we have all been waiting for: Switching to remote state!
    [self.remoteLibManager connectToServer:URL];
}


/**
 *  See [CWWebApplicationState isRemote]
 *
 *  @return See [CWWebApplicationState isRemote]
 */
- (BOOL)isRemote
{
    return self.remoteLibManager.isActive;
}


/**
 *  See [CWWebApplicationState canBecomeRemote]
 *
 *  @return See [CWWebApplicationState canBecomeRemote]
 */
- (BOOL)canBecomeRemote
{
    return [self isRemote] == NO;
}

@end
