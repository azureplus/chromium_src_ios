// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/app_launcher/app_launcher_tab_helper.h"

#import <UIKit/UIKit.h>

#include "base/memory/ptr_util.h"
#include "base/metrics/histogram_macros.h"
#include "components/reading_list/core/reading_list_model.h"
#import "ios/chrome/browser/app_launcher/app_launcher_tab_helper_delegate.h"
#include "ios/chrome/browser/reading_list/reading_list_model_factory.h"
#import "ios/chrome/browser/tabs/legacy_tab_helper.h"
#import "ios/chrome/browser/tabs/tab.h"
#import "ios/chrome/browser/web/app_launcher_abuse_detector.h"
#import "ios/web/public/navigation_item.h"
#import "ios/web/public/navigation_manager.h"
#import "ios/web/public/url_scheme_util.h"
#import "ios/web/public/web_client.h"
#import "net/base/mac/url_conversions.h"
#include "url/gurl.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

DEFINE_WEB_STATE_USER_DATA_KEY(AppLauncherTabHelper);

namespace {

bool IsValidAppUrl(const GURL& app_url) {
  if (!app_url.is_valid())
    return false;

  if (!app_url.has_scheme())
    return false;

  // If the url is a direct FIDO U2F x-callback call, consider it as invalid, to
  // prevent pages from spoofing requests with different origins.
  if (app_url.SchemeIs("u2f-x-callback"))
    return false;

  // Block attempts to open this application's settings in the native system
  // settings application.
  if (app_url.SchemeIs("app-settings"))
    return false;
  return true;
}

// This enum used by the Applauncher to log to UMA, if App launching request was
// allowed or blocked.
// These values are persisted to logs. Entries should not be renumbered and
// numeric values should never be reused.
enum class ExternalURLRequestStatus {
  kMainFrameRequestAllowed = 0,
  kSubFrameRequestAllowed = 1,
  kSubFrameRequestBlocked = 2,
  kCount,
};

}  // namespace

void AppLauncherTabHelper::CreateForWebState(
    web::WebState* web_state,
    AppLauncherAbuseDetector* abuse_detector,
    id<AppLauncherTabHelperDelegate> delegate) {
  DCHECK(web_state);
  if (!FromWebState(web_state)) {
    web_state->SetUserData(UserDataKey(),
                           base::WrapUnique(new AppLauncherTabHelper(
                               web_state, abuse_detector, delegate)));
  }
}

AppLauncherTabHelper::AppLauncherTabHelper(
    web::WebState* web_state,
    AppLauncherAbuseDetector* abuse_detector,
    id<AppLauncherTabHelperDelegate> delegate)
    : web::WebStatePolicyDecider(web_state),
      web_state_(web_state),
      abuse_detector_(abuse_detector),
      delegate_(delegate),
      weak_factory_(this) {}

AppLauncherTabHelper::~AppLauncherTabHelper() = default;

bool AppLauncherTabHelper::RequestToLaunchApp(const GURL& url,
                                              const GURL& source_page_url,
                                              bool link_tapped) {
  // Don't open external application if chrome is not active.
  if ([[UIApplication sharedApplication] applicationState] !=
      UIApplicationStateActive) {
    return false;
  }

  // Don't try to open external application if a prompt is already active.
  if (is_prompt_active_)
    return false;

  [abuse_detector_ didRequestLaunchExternalAppURL:url
                                fromSourcePageURL:source_page_url];
  ExternalAppLaunchPolicy policy =
      [abuse_detector_ launchPolicyForURL:url
                        fromSourcePageURL:source_page_url];
  switch (policy) {
    case ExternalAppLaunchPolicyBlock: {
      return false;
    }
    case ExternalAppLaunchPolicyAllow: {
      return [delegate_ appLauncherTabHelper:this
                            launchAppWithURL:url
                                  linkTapped:link_tapped];
    }
    case ExternalAppLaunchPolicyPrompt: {
      is_prompt_active_ = true;
      base::WeakPtr<AppLauncherTabHelper> weak_this =
          weak_factory_.GetWeakPtr();
      GURL copied_url = url;
      GURL copied_source_page_url = source_page_url;
      [delegate_ appLauncherTabHelper:this
          showAlertOfRepeatedLaunchesWithCompletionHandler:^(
              BOOL user_allowed) {
            if (!weak_this.get())
              return;
            if (user_allowed) {
              // By confirming that user wants to launch the application, there
              // is no need to check for |link_tapped|.
              [delegate_ appLauncherTabHelper:weak_this.get()
                             launchAppWithURL:copied_url
                                   linkTapped:YES];
            } else {
              // TODO(crbug.com/674649): Once non modal dialogs are implemented,
              // update this to always prompt instead of blocking the app.
              [abuse_detector_ blockLaunchingAppURL:copied_url
                                  fromSourcePageURL:copied_source_page_url];
            }
            is_prompt_active_ = false;
          }];
      return true;
    }
  }
}

bool AppLauncherTabHelper::ShouldAllowRequest(
    NSURLRequest* request,
    const web::WebStatePolicyDecider::RequestInfo& request_info) {
  GURL request_url = net::GURLWithNSURL(request.URL);
  if (web::UrlHasWebScheme(request_url) ||
      web::GetWebClient()->IsAppSpecificURL(request_url) ||
      request_url.SchemeIs(url::kFileScheme) ||
      request_url.SchemeIs(url::kAboutScheme)) {
    // This URL can be handled by the WebState and doesn't require App launcher
    // handling.
    return true;
  }

  ExternalURLRequestStatus request_status = ExternalURLRequestStatus::kCount;

  if (request_info.target_frame_is_main) {
    // TODO(crbug.com/852489): Check if the source frame should also be
    // considered.
    request_status = ExternalURLRequestStatus::kMainFrameRequestAllowed;
  } else {
    request_status = request_info.has_user_gesture
                         ? ExternalURLRequestStatus::kSubFrameRequestAllowed
                         : ExternalURLRequestStatus::kSubFrameRequestBlocked;
  }
  DCHECK_NE(request_status, ExternalURLRequestStatus::kCount);
  UMA_HISTOGRAM_ENUMERATION("WebController.ExternalURLRequestBlocking",
                            request_status, ExternalURLRequestStatus::kCount);
  // Request is blocked.
  if (request_status == ExternalURLRequestStatus::kSubFrameRequestBlocked)
    return false;

  Tab* tab = LegacyTabHelper::GetTabForWebState(web_state_);

  // If this is a Universal 2nd Factory (U2F) call, the origin needs to be
  // checked to make sure it's secure and then update the |request_url| with
  // the generated x-callback GURL based on x-callback-url specs.
  if (request_url.SchemeIs("u2f")) {
    GURL origin = web_state_->GetNavigationManager()
                      ->GetLastCommittedItem()
                      ->GetURL()
                      .GetOrigin();
    request_url = [tab XCallbackFromRequestURL:request_url originURL:origin];
  }

  const GURL& source_url = request_info.source_url;
  bool is_link_transition = ui::PageTransitionTypeIncludingQualifiersIs(
      request_info.transition_type, ui::PAGE_TRANSITION_LINK);
  if (IsValidAppUrl(request_url) &&
      RequestToLaunchApp(request_url, source_url, is_link_transition)) {
    // Clears pending navigation history after successfully launching the
    // external app.
    web_state_->GetNavigationManager()->DiscardNonCommittedItems();

    // When opening applications, the navigation is cancelled. Report the
    // opening of the application to the ReadingListWebStateObserver to mark the
    // entry as read if needed.
    if (source_url.is_valid()) {
      ReadingListModel* model =
          ReadingListModelFactory::GetForBrowserState(tab.browserState);
      if (model && model->loaded())
        model->SetReadStatus(source_url, true);
    }
  }
  return false;
}
