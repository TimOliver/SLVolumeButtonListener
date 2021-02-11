//
//  SLViewController.h
//  VolumeTester
//
//  Created by John Papandriopoulos on 3/14/12.
//  Copyright (c) 2012 SnappyLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SLVolumeButtonListener.h"


//=============================================================================
@interface SLViewController : UIViewController<
    SLVolumeButtonListenerDelegate
> {
    
@protected

    // For volume button events
    SLVolumeButtonListener* _volumeListener;
}

// UI Components
@property (nonatomic, retain) IBOutlet UIImageView* upImageView;
@property (nonatomic, retain) IBOutlet UIImageView* downImageView;
@property (nonatomic, retain) IBOutlet UISwitch* enableSwitch;

@end
