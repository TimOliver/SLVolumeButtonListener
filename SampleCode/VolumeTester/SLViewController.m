//
//  SLViewController.m
//  VolumeTester
//
//  Created by John Papandriopoulos on 3/14/12.
//  Copyright (c) 2012 SnappyLabs. All rights reserved.
//

#import "SLViewController.h"
#import "SLVolumeButtonListener.h"


//=============================================================================
@interface SLViewController ()

// Update the button UI and animate the button press on activation
- (void)_setButton:(SLVolumeButtonState)button state:(BOOL)active;

// Start/stop the volume test depending on UI state
- (IBAction)_controlVolumeTest:(UISwitch*)sender;

@end


//=============================================================================
@implementation SLViewController

//----------------------------------------------------------------------------
@synthesize upImageView = _upImageView;
@synthesize downImageView = _downImageView;
@synthesize enableSwitch = _enableSwitch;


//============================================================================
#pragma mark - Public implementation

//----------------------------------------------------------------------------
- (void)dealloc {

    [_upImageView release];
    [_downImageView release];
    [_enableSwitch release];

    [_volumeListener release];

    [super dealloc];
}


//----------------------------------------------------------------------------
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // Set default state to inactive
    [self _setButton:SLVolumeButtonStateUp state:NO];
    [self _setButton:SLVolumeButtonStateDown state:NO];

    // Configure the volume button listener
    _volumeListener =
        [[SLVolumeButtonListener alloc] initForParentView:self.view];
    _volumeListener.delegate = self;

    [self _controlVolumeTest:_enableSwitch];
}


//----------------------------------------------------------------------------
- (void)viewDidUnload {

    [_upImageView release], _upImageView = nil;
    [_downImageView release], _downImageView = nil;

    [_volumeListener release], _volumeListener = nil;
    [_enableSwitch release], _enableSwitch = nil;

    [super viewDidUnload];
}


//----------------------------------------------------------------------------
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

    // Only support portrait orientation
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


//============================================================================
#pragma mark - Private implementation

//----------------------------------------------------------------------------
- (void)_setButton:(SLVolumeButtonState)button state:(BOOL)active {

    // Select the right image view
    UIImageView* imageView =
        (button == SLVolumeButtonStateUp)
            ? _upImageView
            : _downImageView;

    // Select the image filename, from Volume{Up, Down}{Glow, ""}.png
    NSString* imageName =
        [NSString stringWithFormat:@"Volume%s%s", 
            (button == SLVolumeButtonStateUp)
                ? "Up"
                : "Down",
            (active)
                ? "Glow"
                : ""
        ];

    imageView.image = [UIImage imageNamed:imageName];

    // We will animate the active state only
    if (active) {
        [UIView animateWithDuration:0.05
                         animations:^{

            const CGFloat scale = 1.05;
            imageView.transform = CGAffineTransformMakeScale(scale, scale);
        } 
                         completion:^(BOOL finished) {

            imageView.transform = CGAffineTransformIdentity;
        }];
    }
}


//----------------------------------------------------------------------------
- (IBAction)_controlVolumeTest:(UISwitch*)sender {

    if (!_volumeListener) {

        // Not available...
        UIAlertView *alert =
            [[UIAlertView alloc] initWithTitle:@"Volume buttons unavailable"
                                       message:@"You need iOS 5+ to use enable the volume buttons, sorry!"
                                      delegate:nil
                             cancelButtonTitle:@"OK"
                             otherButtonTitles:nil];
        
        [alert show];
        [alert release];

        // Turn the feature back off...
        sender.on = NO;
    }

    // Control the volume button listener
    NSLog(@"Volume test enabled? %s", (sender.on) ?"yes" :"no");
    _volumeListener.enabled = sender.on;

    // Configure the audio session (and user control over ringer volume)
    AudioSessionSetActive(sender.on);
}


//============================================================================
#pragma mark - SLVolumeButtonListenerDelegate implementation

//----------------------------------------------------------------------------
- (void)volumeButtonDidPress:(id)sender state:(SLVolumeButtonState)button {

    // Update the UI: button is active
    [self _setButton:button state:YES];
    
    NSLog(
        @"Volume %c button press event",
        (button == SLVolumeButtonStateUp)
            ? '+'
            : '-'
    );
}


//----------------------------------------------------------------------------
- (void)volumeButtonDidPressStart:(id)sender state:(SLVolumeButtonState)button {

    NSLog(
        @"Volume %c button start event",
        (button == SLVolumeButtonStateUp)
            ? '+'
            : '-'
    );
}


//----------------------------------------------------------------------------
- (void)volumeButtonDidPressEnd:(id)sender state:(SLVolumeButtonState)button {

    // Update the UI: button is inactive
    [self _setButton:button state:NO];

    NSLog(
        @"Volume %c button end event",
        (button == SLVolumeButtonStateUp)
            ? '+'
            : '-'
    );
}

@end
