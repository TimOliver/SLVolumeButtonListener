# SLVolumeButtonListener
***WARNING: This class SHOULD NEVER be used in a production iOS app. It was released under a license that is incompatible with the App Store, and explicitly disobeys App Store Review Guideline 10.5 (Modifying the functions of device hardware buttons). It had been made available for archival/educational purposes only.***

---
`SLVolumeButtonListener` is a class created by [John Papandriopoulos](http://jpap.org) in 2012, designed to detect and intercept when the user physically pressed either of the volume buttons on an iOS device.

It was originally created for [SnappyCam](http://thetechreviewer.com/software/snappycam-pro-review-fastest-ios-camera-app-ever/), a rapid-firing photography app from John's startup company SnappyLabs and was freely available on GitHub under the SnappyLabs account.

When [SnappyLabs was acquired by Apple](http://techcrunch.com/2014/01/04/snappylabs/), the SnappyLabs GitHub account was deactivated, and this class was removed along with it. 

I had downloaded this class before the account was deactivated as I was interested in implementing a similar mechanism in [iComics](http://icomics.co) to enable the ability to turn comic book pages with the volume buttons. I since discovered this would have resulted in iComics being rejected from the App Store, so while I abandoned the feature, I still had this class kicking around my hard drive.

In order to preserve this class in the hopes it still has educational value, I've made it available on GitHub again under my own account.

The original README follows:

---

# Overview #

This repository contains an Objective C class to listen for volume button events on iOS.

Three events are supported, for each of the two hardware buttons (+ Volume up, - Volume down):

1. Volume button press has begun
2. Volume button was pressed (can repeat while the button is held down)
3. Volume button press has ended

A sample Xcode project is included demonstrating the use of the library.

# License #

The source in this repository is distributed under the terms of the GNU General 
Public License.

A separate license suitable for commercial use is available on request.
For further information, please contact licensing@snappylabs.com.