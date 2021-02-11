//
//  Created by John Papandriopoulos on 2/8/12.
//  Copyright (c) 2012 SnappyLabs. All rights reserved.
//
//
// This file is part of the SLVolumeButtonListener library.
// 
// The SLVolumeButtonListener library is free software: you can redistribute it
// and/or modify it under the terms of the GNU General Public License as
// published by the Free Software Foundation, either version 3 of the License,
// or (at your option) any later version.
//
// The SLVolumeButtonListener library is distributed in the hope that it will
// be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with the SLVolumeButtonListener library.  If not,
// see <http://www.gnu.org/licenses/>.
//
// A separate license suitable for commercial use is available on request.
// For further information, please contact <licensing@snappylabs.com>.
//

#import "SLVolumeButtonListener.h"


//=============================================================================
#pragma mark - Constants

/* A tiny delta for offseting the system volume when at the boundary so that
 * both up and down volume events are fired.  It appears that the API uses
 * a float to represent the current volume setting, but the hardware surely
 * cannot have this many volume levels (17-bit precision; while a mixer might
 * have 24-bit precision, most hardware DACs are 16-bit).  The end result is
 * that this offset will have absolutely no perceptible difference in the actual
 * volume output level.
 */
#define kSLVolumeButtonListenerVolumeDelta (1.0/131072.0)


/* Button event timeout (seconds).
 *
 * Because we observe the button state indirectly, via volume changes, there
 * is no "up" button event.  Fortunately, while the button is held down, the
 * volume changes repeatedly so we can use this fact with a timer to detect
 * when the volume no-longer changes, and the button has been lifted.
 *
 * We can further optimize the timeout by noting that the "repeat rate" is
 * faster on the second and subsequent volume changes for a given button
 * press.  Fortunately the repeat rate is independent of the actual volume
 * level: we reset the volume level on each event SO THERE IS ABSOLUTELY NO
 * PERCEPTIBLE VOLUME LEVEL CHANGE to the end-user (even for background iPod
 * music).
 */
#define kSLVolumeButtonListenerButtonTimeoutSlow 650e-3
#define kSLVolumeButtonListenerButtonTimeoutFast 200e-3


//=============================================================================
#pragma mark - Private interface

//-----------------------------------------------------------------------------
@interface SLVolumeButtonListener ()

// Notification from C-land of a volume change event
- (void)_callbackVolumeDidChange:(float)newVolume;

// Application lifecycle events
- (void)_applicationDidBecomeActive:(NSNotification*)notification;
- (void)_applicationDidEnterBackground:(NSNotification*)notification;

// Fire button lifted event
- (void)_fireButtonLiftedEvent:(NSNumber*)stateObject;

// Are we running on iOS 5+?
- (BOOL)_validateSystemVersion;

@end


//=============================================================================
#pragma mark - C callbacks

//-----------------------------------------------------------------------------
void SLVolumeButtonListenerCallback(
    void *inClientData,
    AudioSessionPropertyID inID,
    UInt32 inDataSize,
    const void *inData
) {
    SLVolumeButtonListener* listener = (SLVolumeButtonListener*)inClientData;
    const float newVolume = *(float*)inData;
    
    // Notify Objective C-land of the event...
    [listener _callbackVolumeDidChange:newVolume];
}


//=============================================================================
@implementation SLVolumeButtonListener

//-----------------------------------------------------------------------------
@synthesize delegate = _delegate;
@synthesize enabled = _enabled;


//-----------------------------------------------------------------------------
- (id)initForParentView:(UIView*)view {
    
    self = [super init];
    if (self) {

        if (![self _validateSystemVersion]) {
            NSLog(@"Warning: disabling SLVolumeButtonListener on iOS < 5.0.0");
            [self release];
            return nil;
        }
        
        // Create the volume view on a container that has zero width/height
        const CGRect frame = CGRectZero;
        _containerView = [[UIView alloc] initWithFrame:frame];
        _containerView.autoresizesSubviews = NO;

        // We create the volume view with zero width/height too, and don't
        // care if it resizes itself (which it doesn't appear to).
        _volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        [_containerView addSubview:_volumeView];

        [view addSubview:_containerView];
        
        // Use this to programatically change the system volume
        _musicPlayer =
            [[MPMusicPlayerController applicationMusicPlayer] retain];

        // Hook into volume control events
        AudioSessionAddPropertyListener(
            kAudioSessionProperty_CurrentHardwareOutputVolume,
            SLVolumeButtonListenerCallback,
            self
        );

        // Disabled to begin
        _volumeView.hidden = YES;
        _enabled = NO;

        NSNotificationCenter* notifyCenter =
            [NSNotificationCenter defaultCenter];

        // Get notified of application activation
        [notifyCenter addObserver:self 
                         selector:@selector(_applicationDidBecomeActive:) 
                             name:UIApplicationDidBecomeActiveNotification
                           object:nil];

        // Get notified of application backgrounding
        [notifyCenter addObserver:self 
                         selector:@selector(_applicationDidEnterBackground:) 
                             name:UIApplicationDidEnterBackgroundNotification
                           object:nil];
    }
    return self;
}


//-----------------------------------------------------------------------------
- (void)dealloc {

    // Stop listening for volume changes
    AudioSessionRemovePropertyListenerWithUserData(
        kAudioSessionProperty_CurrentHardwareOutputVolume,
        SLVolumeButtonListenerCallback,
        self
    );
    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter removeObserver:self];

    if (_enabled) {
        // Restore the application volume level
        _musicPlayer.volume = _startVolume;
    }

    // Disconnect container from the view hierarchy
    [_containerView removeFromSuperview];

    // Clean up everything else...
    [_containerView release];
    [_musicPlayer release];
    [_volumeView release];

    [super dealloc];
}


//-----------------------------------------------------------------------------
- (void)setVolume:(float)volume {
    
    if (_enabled) {

        // Save the desired application volume level for later reset
        _startVolume = volume;
        NSLog(@"Starting application volume: %f", _startVolume);

        // This is the volume level we will compare to on a volume-change event
        // callback.  It must not lie on a boundary, otherwise we lose the
        // callback at that boundary.  (The fixup below takes care of this.)
        _resetVolume = _startVolume;

        // Make sure the volume is not on a boundary
        if (_resetVolume == 1.0) {
            _resetVolume -= kSLVolumeButtonListenerVolumeDelta;
        }
        else if (_resetVolume == 0.0) {
            _resetVolume += kSLVolumeButtonListenerVolumeDelta;
        }

        // Enact the effective volume level
        NSLog(@"Application volume: %f", _resetVolume);
        _musicPlayer.volume = _resetVolume;
    }
    else {

        // Set the desired application volume level
        _musicPlayer.volume = volume;
    }
}


//-----------------------------------------------------------------------------
- (float)volume {

    // Return the "current" application volume level
    return (_enabled) ? _startVolume : _musicPlayer.volume;
}


//-----------------------------------------------------------------------------
- (void)setEnabled:(BOOL)enabled {

    if (enabled == _enabled) {
        // Ignore
        return;
    }
        
    if (_enabled) {

        // Prepare to be disabled
        _enabled = NO;

        // Restore the starting volume level
        _musicPlayer.volume = _startVolume;

        /* Re-enable the volume display
         *
         * We do this on the next-next run loop because for some reason there's
         * a bit of a lag between using the volume control and it still being
         * hidden by the volume view.
         */
        dispatch_async(dispatch_get_main_queue(), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                _volumeView.hidden = YES;
            });
        });
    }
    else {

        // Prepare to be enabled
        _enabled = YES;

        // Disable the volume display
        _volumeView.hidden = NO;

        /* Set up the starting volume level based on the now-current application
         * volume level.
         *
         * We do this on the next-next run loop because for some reason there's
         * a bit of a lag between disabling the volume display above and it
         * being effectual.
         */
        dispatch_async(dispatch_get_main_queue(), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.volume = _musicPlayer.volume;
            });
        });
    }
}


//-----------------------------------------------------------------------------
- (void)setDelegate:(id<SLVolumeButtonListenerDelegate>)delegate {

    _delegate = delegate;
    
    _delegateCaps.didPress =
        [_delegate respondsToSelector:@selector(volumeButtonDidPress:state:)];
    _delegateCaps.didPressStart =
        [_delegate respondsToSelector:@selector(volumeButtonDidPressStart:state:)];
    _delegateCaps.didPressEnd =
        [_delegate respondsToSelector:@selector(volumeButtonDidPressEnd:state:)];    
}


//============================================================================
#pragma mark - Private implementation

//-----------------------------------------------------------------------------
- (BOOL)_validateSystemVersion {

    // Parse for the iOS major version number
    NSString* systemVersion = [UIDevice currentDevice].systemVersion;
    NSArray *versionComponents = [systemVersion componentsSeparatedByString:@"."];
    const int majorVersion = [[versionComponents objectAtIndex:0] intValue];

    // Pass validation if we're iOS 5.x.x or greater
    return majorVersion >= 5;
}


//-----------------------------------------------------------------------------
- (void)_callbackVolumeDidChange:(float)newVolume {

    if (!_enabled || (newVolume == _resetVolume)) {
        // Ignore volume change notification
        return;
    }

    #ifdef DEBUG
        // Show the button-repeat lag
        static NSTimeInterval lastChange = NAN;
        if (lastChange != NAN) {
            const NSTimeInterval timeChange =
                [NSDate timeIntervalSinceReferenceDate] - lastChange;
            if (timeChange < 1.0) {
                NSLog(@"Time since last volume change: %0.3f", timeChange);
            }
        }
        lastChange = [NSDate timeIntervalSinceReferenceDate];
    #endif // DEBUG
    
    // Record volume movement
    const SLVolumeButtonState state =
        (newVolume > _resetVolume)
            ? SLVolumeButtonStateUp
            : SLVolumeButtonStateDown;

    // Cancel any previous end-event callback.
    // Note that we rely on NSNumber's isEqual: to look up the right request.
    NSNumber* stateObject = [NSNumber numberWithInt:state];
    [NSObject cancelPreviousPerformRequestsWithTarget:self 
                                             selector:@selector(_fireButtonLiftedEvent:) 
                                               object:stateObject];

    // Reset the volume setting immediately so the user doesn't hear the
    // change if they're playing audio in the background
    _enabled = NO;
    _musicPlayer.volume = _resetVolume;
    _enabled = YES;

    // Select the timeout based on whether this is the first button press
    // or if we think the button was already held down...
    const NSTimeInterval timeout =
        (!_buttonActive[state])
            ? kSLVolumeButtonListenerButtonTimeoutSlow
            : kSLVolumeButtonListenerButtonTimeoutFast;

    // Fire start callback
    if (!_buttonActive[state]) {
        _buttonActive[state] = YES;
        if (_delegateCaps.didPressStart) {
            [_delegate volumeButtonDidPressStart:self state:state];
        }
    }

    // Fire press callback
    if (_delegateCaps.didPress) {
        [_delegate volumeButtonDidPress:self state:state];
    }

    // Fire end callback after a timeout to indicate button depress.
    // If the button is still held down then we'll be back here again,
    // and this call will be canceled as above, then the callback reset.
    [self performSelector:@selector(_fireButtonLiftedEvent:) 
               withObject:stateObject
               afterDelay:timeout];
}


//-----------------------------------------------------------------------------
- (void)_applicationDidEnterBackground:(NSNotification*)notification {

    // Disable audio session before we background
    if (_enabled) {
        AudioSessionSetActive(false);
    }
}


//-----------------------------------------------------------------------------
- (void)_applicationDidBecomeActive:(NSNotification*)notification {

    // Reset audio session on resume
    #ifdef SL_ALWAYS_RESTORE_AUDIOSESSION

        AudioSessionSetActive(true);
    
    #else

        /* The only problem with conditioning this on our enabled state is:
         *   + if the app is backgrounded when we're not enabled
         *   + the user then enables us on resume
         *   + the caller has not set up the audio session
         *   + then the listener will fail to work.
         *
         * These reasons are why we have the SL_ALWAYS_RESTORE_AUDIOSESSION
         * compile-time option.  If you are handling the audio session code
         * elsewhere in the app, you may want to disable this compile option.
         */
        if (_enabled) {
            AudioSessionSetActive(true);
        }

    #endif
}


//-----------------------------------------------------------------------------
- (void)_fireButtonLiftedEvent:(NSNumber*)stateObject {

    // Unpack the state value...
    const SLVolumeButtonState state =
        (SLVolumeButtonState)[stateObject intValue];
    
    // Fire end callback
    if (_buttonActive[state]) {

        _buttonActive[state] = NO;
        if (_delegateCaps.didPressEnd) {
            [_delegate volumeButtonDidPressEnd:self state:state];
        }
    }
}

@end

