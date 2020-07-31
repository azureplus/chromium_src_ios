// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_UI_SETTINGS_SAFETY_CHECK_SAFETY_CHECK_CONSUMER_H_
#define IOS_CHROME_BROWSER_UI_SETTINGS_SAFETY_CHECK_SAFETY_CHECK_CONSUMER_H_

#import <UIKit/UIKit.h>

#import "ios/chrome/browser/ui/table_view/table_view_model.h"

// Consumer protocol for safety check.
@protocol SafetyCheckConsumer <NSObject>

// Initializes the check types section with |items|.
- (void)setCheckItems:(NSArray<TableViewItem*>*)items;

// Initializes the check start section with |item|.
- (void)setCheckStartItem:(TableViewItem*)item;

@end

#endif  // IOS_CHROME_BROWSER_UI_SETTINGS_SAFETY_CHECK_SAFETY_CHECK_CONSUMER_H_
