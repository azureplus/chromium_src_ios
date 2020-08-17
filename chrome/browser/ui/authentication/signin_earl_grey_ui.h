// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_UI_AUTHENTICATION_SIGNIN_EARL_GREY_UI_H_
#define IOS_CHROME_BROWSER_UI_AUTHENTICATION_SIGNIN_EARL_GREY_UI_H_

#import <Foundation/Foundation.h>

#import "ios/chrome/browser/ui/authentication/cells/signin_promo_view_constants.h"

@class FakeChromeIdentity;

typedef NS_ENUM(NSInteger, SignOutConfirmation) {
  SignOutConfirmationManagedUser,
  SignOutConfirmationNonManagedUser,
  SignOutConfirmationNonManagedUserWithClearedData,
};

// Test methods that perform sign in actions on Chrome UI.
@interface SigninEarlGreyUI : NSObject

// Signs the account for |fakeIdentity| into Chrome through the Settings screen.
// There will be a GREYAssert if the tools menus is open when calling this
// method or if the account is not successfully signed in.
+ (void)signinWithFakeIdentity:(FakeChromeIdentity*)fakeIdentity;

// Signs the primary account out of Chrome through the accounts list screen.
// Taps the "Sign Out" button to begin flow. Note that managed accounts cannot
// go through this flow. There will be a GREYAssert if the tools menus is open
// when calling this method or if the account is not successfully signed out.
+ (void)signOut;

// Signs the primary account out of Chrome through the accounts list screen.
// Taps the "Sign out and clear data from this device" button to begin flow.
// There will be a GREYAssert if the tools menus is open when calling this
// method or if the account is not successfully signed out.
+ (void)signOutAndClearDataFromDevice;

// Taps on the settings link in the sign-in view. The sign-in view has to be
// opened before calling this method.
+ (void)tapSettingsLink;

// Selects an identity when the identity chooser dialog is presented. The dialog
// is confirmed, but it doesn't validated the user consent page.
+ (void)selectIdentityWithEmail:(NSString*)userEmail;

// Confirms the sign in confirmation page, scrolls first to make the OK button
// visible on short devices (e.g. iPhone 5s).
+ (void)confirmSigninConfirmationDialog;

// Taps on the "ADD ACCOUNT" button in the unified consent, to display the
// SSO dialog.
// This method should only be used with UnifiedConsent flag.
+ (void)tapAddAccountButton;

// Checks that the sign-in promo view (with a close button) is visible using the
// right mode.
+ (void)checkSigninPromoVisibleWithMode:(SigninPromoViewMode)mode;

// Checks that the sign-in promo view is visible using the right mode. If
// |closeButton| is set to YES, the close button in the sign-in promo has to be
// visible.
+ (void)checkSigninPromoVisibleWithMode:(SigninPromoViewMode)mode
                            closeButton:(BOOL)closeButton;

// Checks that the sign-in promo view is not visible.
+ (void)checkSigninPromoNotVisible;

// Taps the appropriate action label on the sign-out dialog for the given
// |signOutConfirmation| profile and signs out from the current identity.
+ (void)signOutWithSignOutConfirmation:(SignOutConfirmation)signOutConfirmation;

// Taps "Remove account from this device" button and follow-up confirmation.
// Assumes the user is on the Settings screen.
+ (void)tapRemoveAccountFromDeviceWithFakeIdentity:
    (FakeChromeIdentity*)fakeIdentity;

@end

#endif  // IOS_CHROME_BROWSER_UI_AUTHENTICATION_SIGNIN_EARL_GREY_UI_H_
