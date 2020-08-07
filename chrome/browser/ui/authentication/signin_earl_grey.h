// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_UI_AUTHENTICATION_SIGNIN_EARL_GREY_H_
#define IOS_CHROME_BROWSER_UI_AUTHENTICATION_SIGNIN_EARL_GREY_H_

#import <Foundation/Foundation.h>

#include "base/compiler_specific.h"
#import "ios/testing/earl_grey/base_eg_test_helper_impl.h"

@protocol GREYMatcher;
@class FakeChromeIdentity;

#define SigninEarlGrey \
  [SigninEarlGreyImpl invokedFromFile:@"" __FILE__ lineNumber:__LINE__]

// Methods used for the EarlGrey tests.
// TODO(crbug.com/974833): Consider moving these into ChromeEarlGrey.
@interface SigninEarlGreyImpl : BaseEGTestHelperImpl

// Returns a fake identity.
- (FakeChromeIdentity*)fakeIdentity1;

// Returns a second fake identity.
- (FakeChromeIdentity*)fakeIdentity2;

// Returns a fake managed identity.
- (FakeChromeIdentity*)fakeManagedIdentity;

// Adds |fakeIdentity| to the fake identity service.
- (void)addFakeIdentity:(FakeChromeIdentity*)fakeIdentity;

// Removes |fakeIdentity| from the fake identity service asynchronously to
// simulate identity removal from the device.
- (void)forgetFakeIdentity:(FakeChromeIdentity*)fakeIdentity;

// Induces a GREYAssert if |fakeIdentity| is not signed in to the active
// profile.
- (void)checkSignedInWithFakeIdentity:(FakeChromeIdentity*)fakeIdentity;

// Induces a GREYAssert if an identity is signed in.
- (void)checkSignedOut;

// Wait until |matcher| is accessible (not nil).
- (void)waitForMatcher:(id<GREYMatcher>)matcher;

@end

#endif  // IOS_CHROME_BROWSER_UI_AUTHENTICATION_SIGNIN_EARL_GREY_H_