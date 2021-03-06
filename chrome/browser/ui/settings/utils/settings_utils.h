// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_UI_SETTINGS_UTILS_SETTINGS_UTILS_H_
#define IOS_CHROME_BROWSER_UI_SETTINGS_UTILS_SETTINGS_UTILS_H_

#import <UIKit/UIKit.h>

#import "ios/chrome/browser/procedural_block_types.h"

@protocol ApplicationCommands;

// Returns a ProceduralBlockWithURL that uses the dispatcher and opens url
// (parameter to the block) in a new tab.
ProceduralBlockWithURL BlockToOpenURL(UIResponder* responder,
                                      id<ApplicationCommands> handler);

// Returns an UITableViewStyle according to the state of the kSettingsRefresh
// flag and the width of the current device.
UITableViewStyle SettingsTableViewStyle();

#endif  // IOS_CHROME_BROWSER_UI_SETTINGS_UTILS_SETTINGS_UTILS_H_
