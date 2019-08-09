// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_UI_BADGES_BADGE_VIEW_CONTROLLER_H_
#define IOS_CHROME_BROWSER_UI_BADGES_BADGE_VIEW_CONTROLLER_H_

#import <UIKit/UIKit.h>

#import "ios/chrome/browser/ui/badges/badge_consumer.h"
#import "ios/chrome/browser/ui/fullscreen/fullscreen_ui_element.h"

@class BadgeButtonFactory;
@protocol InfobarCommands;

// Manages badges to display that are received through BadgeConsumer. Currently
// only displays the newest badge.
@interface BadgeViewController
    : UIViewController <BadgeConsumer, FullscreenUIElement>

// The dispatcher for badge button actions.
@property(nonatomic, weak) id<InfobarCommands> dispatcher;

@end

#endif  // IOS_CHROME_BROWSER_UI_BADGES_BADGE_VIEW_CONTROLLER_H_
