// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_UI_DOWNLOAD_RADIAL_PROGRESS_VIEW_H_
#define IOS_CHROME_BROWSER_UI_DOWNLOAD_RADIAL_PROGRESS_VIEW_H_

#import <UIKit/UIKit.h>

// View that draws progress as arc. Arc starts at 12 o'clock and drawn
// clockwise. The arc color is tintColor.
@interface RadialProgressView : UIView

// Progress in [0.0f, 1.0f] range.
@property(nonatomic) float progress;

// The line width used when stroking the progress arc.
@property(nonatomic) CGFloat lineWidth;

@end

#endif  // IOS_CHROME_BROWSER_UI_DOWNLOAD_RADIAL_PROGRESS_VIEW_H_
