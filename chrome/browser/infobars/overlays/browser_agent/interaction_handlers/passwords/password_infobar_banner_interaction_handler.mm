// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/infobars/overlays/browser_agent/interaction_handlers/passwords/password_infobar_banner_interaction_handler.h"

#include "base/logging.h"
#include "ios/chrome/browser/infobars/infobar_ios.h"
#import "ios/chrome/browser/overlays/public/infobar_banner/save_password_infobar_banner_overlay.h"
#import "ios/chrome/browser/passwords/ios_chrome_save_password_infobar_delegate.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#pragma mark - InfobarBannerInteractionHandler

PasswordInfobarBannerInteractionHandler::
    PasswordInfobarBannerInteractionHandler()
    : InfobarBannerInteractionHandler(
          SavePasswordInfobarBannerOverlayRequestConfig::RequestSupport()) {}

PasswordInfobarBannerInteractionHandler::
    ~PasswordInfobarBannerInteractionHandler() = default;

void PasswordInfobarBannerInteractionHandler::BannerVisibilityChanged(
    InfoBarIOS* infobar,
    bool visible) {
  if (visible) {
    GetInfobarDelegate(infobar)->InfobarPresenting(/*automatic=*/YES);
  } else {
    GetInfobarDelegate(infobar)->InfobarDismissed();
  }
}

void PasswordInfobarBannerInteractionHandler::MainButtonTapped(
    InfoBarIOS* infobar) {
  infobar->set_accepted(GetInfobarDelegate(infobar)->Accept());
}

void PasswordInfobarBannerInteractionHandler::ShowModalButtonTapped(
    InfoBarIOS* infobar,
    web::WebState* web_state) {
  // TODO(crbug.com/1033154): Add support for showing modal UI via
  // OverlayPresenter.
}

void PasswordInfobarBannerInteractionHandler::BannerDismissedByUser(
    InfoBarIOS* infobar) {
  // Notify the delegate that a user-initiated dismissal has been triggered.
  // NOTE: InfoBarDismissed() (camel cased) is used to notify the delegate that
  // the user initiated the upcoming dismissal (i.e. swiped to dismiss in the
  // refresh UI).  InfobarDismissed() (not camel cased) is called in
  // BannerVisibilityChanged() to notify the delegate of the dismissal of the
  // UI.
  GetInfobarDelegate(infobar)->InfoBarDismissed();
}

#pragma mark - Private

IOSChromeSavePasswordInfoBarDelegate*
PasswordInfobarBannerInteractionHandler::GetInfobarDelegate(
    InfoBarIOS* infobar) {
  IOSChromeSavePasswordInfoBarDelegate* delegate =
      IOSChromeSavePasswordInfoBarDelegate::FromInfobarDelegate(
          infobar->delegate());
  DCHECK(delegate);
  return delegate;
}
