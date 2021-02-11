//
//  SLAppDelegate.m
//  VolumeTester
//
//  Created by John Papandriopoulos on 3/14/12.
//  Copyright (c) 2012 SnappyLabs. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "SLAppDelegate.h"

#import "SLViewController.h"


//=============================================================================
@implementation SLAppDelegate

//-----------------------------------------------------------------------------
@synthesize window = _window;
@synthesize viewController = _viewController;


//-----------------------------------------------------------------------------
- (void)dealloc {

    [_window release];
    [_viewController release];
    [super dealloc];
}


//-----------------------------------------------------------------------------
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    OSStatus error;
    
    error = AudioSessionInitialize(NULL, NULL, NULL, NULL);
    if (error == noErr) {

        // Set the audio cateogry
        const UInt32 category = kAudioSessionCategory_AmbientSound;	
        error = AudioSessionSetProperty(
            kAudioSessionProperty_AudioCategory, 
            sizeof(category), &category
        );
        if (error != noErr) {
            NSLog(@"Failed to configure audio category.");
        }
    }
    else {
        NSLog(@"Failed to initialize audio session.");
    }
    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];

    self.viewController = [[[SLViewController alloc] initWithNibName:@"SLViewController" bundle:nil] autorelease];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];

    return YES;
}

@end
