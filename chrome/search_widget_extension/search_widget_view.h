// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_SEARCH_WIDGET_EXTENSION_SEARCH_WIDGET_VIEW_H_
#define IOS_CHROME_SEARCH_WIDGET_EXTENSION_SEARCH_WIDGET_VIEW_H_

#import <UIKit/UIKit.h>

// Protocol to be implemented by targets for user actions coming from the search
// widget view.
@protocol SearchWidgetViewActionTarget

// Called when the user taps the Search button.
- (void)openSearch:(id)sender;
// Called when the user taps the Incognito Search button.
- (void)openIncognito:(id)sender;
// Called when the user taps the Voice Search button.
- (void)openVoice:(id)sender;
// Called when the user taps the QR Code button.
- (void)openQRCode:(id)sender;
// Called when the user taps the Open Copied URL section.
- (void)openCopiedURL:(id)sender;

@end

// View for the search widget, shows two sections. The first section is a row of
// ways to launch the app. The second section displays the current copied URL.
@interface SearchWidgetView : UIView

// Designated initializer, creates the widget view with a |target| for user
// actions. The |primaryVibrancyEffect| and |secondaryVibrancyEffect| are used
// to display view elements.
- (instancetype)initWithActionTarget:(id<SearchWidgetViewActionTarget>)target
               primaryVibrancyEffect:(UIVibrancyEffect*)primaryVibrancyEffect
             secondaryVibrancyEffect:(UIVibrancyEffect*)secondaryVibrancyEffect
    NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder*)aDecoder NS_UNAVAILABLE;

// Sets the copied URL string to be displayed. nil is a valid value to indicate
// there is no copied URL to display.
- (void)setCopiedURLString:(NSString*)URL;

@end

#endif  // IOS_CHROME_SEARCH_WIDGET_EXTENSION_SEARCH_WIDGET_VIEW_H_
