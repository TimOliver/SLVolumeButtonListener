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


#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>


//=============================================================================
#pragma mark - Compile time options

// Define to always restore the audio session whenever the application resumes
// from the background state, regardless of whether the listener is enabled or
// not.
#define SL_ALWAYS_RESTORE_AUDIOSESSION


//=============================================================================
#pragma mark - Constants

//-----------------------------------------------------------------------------
// One value for each physical button
typedef enum SLVolumeButtonState {

    // Volume down button
    SLVolumeButtonStateDown = 0,
    
    // Volume up button
    SLVolumeButtonStateUp
    
} SLVolumeButtonState;

#define SLVolumeButtonStateCount 2


//=============================================================================
#pragma mark - Delegate callback protocol

//-----------------------------------------------------------------------------
@protocol SLVolumeButtonListenerDelegate <NSObject>

@optional

// These repeat automatically as the hardware buttons are held down.
- (void)volumeButtonDidPress:(id)sender state:(SLVolumeButtonState)buttonState;

// These don't repeat with the hardware buttons held down.
- (void)volumeButtonDidPressStart:(id)sender state:(SLVolumeButtonState)buttonState;
- (void)volumeButtonDidPressEnd:(id)sender state:(SLVolumeButtonState)buttonState;

@end


//=============================================================================
@interface SLVolumeButtonListener : NSObject {
    
@protected

    // Delegate capabilities
    struct {
        unsigned int didPress:1;
        unsigned int didPressStart:1;
        unsigned int didPressEnd:1;
    } _delegateCaps;

    // True whenever one of the volume buttons are active
    BOOL _buttonActive[SLVolumeButtonStateCount];
    
    // Starting system hardware volume
    float _startVolume;

    // Volume level we reset to on a callback
    float _resetVolume;

    // We use this to hide the volume control rounded rect on-screen
    MPVolumeView* _volumeView;

    // We use this to change the system volume programatically
    MPMusicPlayerController* _musicPlayer;

    // Container for the MPVolumeView.  It needs to be part of the view
    // hierarchy for the MPVolumeView to do its magic.
    UIView* _containerView;
}

// Delegate for button events
@property (nonatomic, assign) id<SLVolumeButtonListenerDelegate> delegate;

// Set/get current application volume.  This is the only way to change the
// applicaiton volume level while the listener is active.
@property (nonatomic, assign) float volume;

// Enable/disable the listener.  Default is NO (disabled).
@property (nonatomic, assign) BOOL enabled;

/* Designated initializer.  You must specify a UIView that is part of the
 * view hierarchy for the whole thing to work.  The only sub-view that is
 * added will have a zero width/height and therefore will not be visible.
 *
 * NOTE: this class will only work on iOS 5+ by design.  If you hack the code,
 *       you can make it work on iOS 4, but it breaks when the user uses the
 *       mute switch on their device.  It is also unclear whether the code would
 *       be "AppStore safe" when targetting iOS 4.
 */
- (id)initForParentView:(UIView*)view;

@end
