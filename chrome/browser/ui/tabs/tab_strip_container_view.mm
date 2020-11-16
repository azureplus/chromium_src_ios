// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/ui/tabs/tab_strip_container_view.h"

#import "ios/chrome/browser/ui/tabs/tab_strip_view.h"
#include "ios/chrome/browser/ui/util/rtl_geometry.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

@implementation TabStripContainerView

- (UIView*)screenshotForAnimation {
  UIView* tabStripSnapshot =
      [self.tabStripView snapshotViewAfterScreenUpdates:YES];
  tabStripSnapshot.transform =
      [self adjustTransformForRTL:tabStripSnapshot.transform];
  return tabStripSnapshot;
}

- (CGAffineTransform)adjustTransformForRTL:(CGAffineTransform)transform {
  if (!UseRTLLayout()) {
    return transform;
  }
  return CGAffineTransformConcat(transform, CGAffineTransformMakeScale(-1, 1));
}

@end
