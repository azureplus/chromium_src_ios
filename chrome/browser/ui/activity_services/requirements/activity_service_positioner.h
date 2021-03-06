// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_UI_ACTIVITY_SERVICES_REQUIREMENTS_ACTIVITY_SERVICE_POSITIONER_H_
#define IOS_CHROME_BROWSER_UI_ACTIVITY_SERVICES_REQUIREMENTS_ACTIVITY_SERVICE_POSITIONER_H_

#import <UIKit/UIKit.h>

// ActivityServicePositioner contains methods that are used to position the
// activity services menu on the screen.
@protocol ActivityServicePositioner

// Returns the view where the UIActivityViewController
// should be presented.
- (UIView*)sourceView;

// Returns the bounds where the UIActivityViewController's popover should be
// presented.
- (CGRect)sourceRect;

@end

#endif  // IOS_CHROME_BROWSER_UI_ACTIVITY_SERVICES_REQUIREMENTS_ACTIVITY_SERVICE_POSITIONER_H_
