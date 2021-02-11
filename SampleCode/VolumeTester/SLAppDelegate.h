//
//  SLAppDelegate.h
//  VolumeTester
//
//  Created by John Papandriopoulos on 3/14/12.
//  Copyright (c) 2012 SnappyLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SLViewController.h"

//=============================================================================
@interface SLAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) SLViewController *viewController;

@end
