//
//  CCRemoteLibManager.h
//  ConnichiwaClient-Mac
//
//  Created by Mario Schreiner on 06/07/14.
//  Copyright (c) 2014 Mario Schreiner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "CCAppState.h"



/**
 *  The state of this device as a remote device
 */
typedef NS_ENUM(NSInteger, CCRemoteLibraryManagerState)
{
    /**
     *  This device is not connected to any other device as a remote
     */
    CCRemoteLibraryManagerStateDisconnected,
    /**
     *  The device is currently connecting to another device as a remote
     */
    CCRemoteLibraryManagerStateConnecting,
    /**
     *  The device is currently used as a remote
     */
    CCRemoteLibraryManagerStateConnected,
    /**
     *  The device is currently disconnecting from another device and about to give up its remote state
     */
    CCRemoteLibraryManagerStateDisconnecting,
    /**
     *  The device has been soft-disconnected from another device - it is considered the same as the Disconnected state, but the connection is not physically closed yet
     */
    CCRemoteLibraryManagerStateSoftDisconnected
};



@interface CCRemoteLibraryManager : NSObject

/**
 *  The remote webview where the connection to remote devices will be established. Must be set to a UIWebView that is not used for any other purposes. This class will become the delegate of that UIWebView. Also, the UIWebView will automatically be hidden/unhidden depending on the remote state of this devie.
 */
@property (readwrite, strong) WebView *webView;

/**
 *  Initializes a new manager with the given application state
 *
 *  @param appState The application state object of this application
 *
 *  @return a new manager instance
 */
- (instancetype)initWithApplicationState:(id<CCAppState>)appState;

/**
 *  Determines if this device is currently active as a remote
 *
 *  @return true if we are currently connected as a remote device, otherwise false
 */
- (BOOL)isActive;

/**
 *  Connects us as a remote device to the connichiwa webserver at the given URL
 *
 *  @param URL The URL of a connichiwa webserver
 */
- (void)connectToServer:(NSURL *)URL;

/**
 *  Disconnects this device from its currently connected master device if it is connected
 */
- (void)disconnect;

@end
