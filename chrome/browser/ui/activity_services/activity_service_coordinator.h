// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_UI_ACTIVITY_SERVICES_ACTIVITY_SERVICE_COORDINATOR_H_
#define IOS_CHROME_BROWSER_UI_ACTIVITY_SERVICES_ACTIVITY_SERVICE_COORDINATOR_H_

#import "ios/chrome/browser/ui/coordinators/chrome_coordinator.h"

@protocol ActivityServicePositioner;

// ActivityServiceCoordinator provides a public interface for the share
// menu feature.
@interface ActivityServiceCoordinator : ChromeCoordinator

// Provider of the share action location.
@property(nonatomic, readwrite, weak) id<ActivityServicePositioner>
    positionProvider;

@end

#endif  // IOS_CHROME_BROWSER_UI_ACTIVITY_SERVICES_ACTIVITY_SERVICE_COORDINATOR_H_