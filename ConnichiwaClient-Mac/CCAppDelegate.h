//
//  CCAppDelegate.h
//  ConnichiwaClient-Mac
//
//  Created by Mario Schreiner on 06/07/14.
//  Copyright (c) 2014 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <SystemConfiguration/SystemConfiguration.h>

@interface CCAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet WebView *webView;

+ (NSString *)identifier;
+ (NSString *)computerName;

@end
