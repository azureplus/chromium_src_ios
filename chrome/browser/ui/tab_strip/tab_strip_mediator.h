// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_UI_TAB_STRIP_TAB_STRIP_MEDIATOR_H_
#define IOS_CHROME_BROWSER_UI_TAB_STRIP_TAB_STRIP_MEDIATOR_H_

#import <Foundation/Foundation.h>

@protocol TabStripConsumer;
class WebStateList;

// This mediator used to manage model interaction for its consumer.
@interface TabStripMediator : NSObject

// The WebStateList that this mediator listens for any changes on the total
// number of Webstates.
@property(nonatomic, assign) WebStateList* webStateList;

// Designated initializer. Initializer with a TabStripConsumer.
- (instancetype)initWithConsumer:(id<TabStripConsumer>)consumer
    NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

// Preprares the receiver for destruction, disconnecting from all services.
// It is an error for the receiver to dealloc without this having been called
// first.
- (void)disconnect;

@end

#endif  // IOS_CHROME_BROWSER_UI_TAB_STRIP_TAB_STRIP_MEDIATOR_H_
