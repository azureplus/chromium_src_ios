// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/test/earl_grey/chrome_earl_grey_app_interface.h"
#import "base/test/ios/wait_util.h"

#include "base/strings/sys_string_conversions.h"
#import "ios/chrome/test/app/bookmarks_test_util.h"
#import "ios/chrome/test/app/chrome_test_util.h"
#import "ios/chrome/test/app/history_test_util.h"
#include "ios/chrome/test/app/navigation_test_util.h"
#include "ios/chrome/test/app/settings_test_util.h"
#import "ios/chrome/test/app/signin_test_util.h"
#import "ios/chrome/test/app/sync_test_util.h"
#import "ios/chrome/test/app/tab_test_util.h"
#import "ios/testing/nserror_util.h"
#import "ios/web/public/test/earl_grey/js_test_util.h"
#import "ios/web/public/test/element_selector.h"
#import "ios/web/public/test/web_view_content_test_util.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

using base::test::ios::kWaitForPageLoadTimeout;
using base::test::ios::kWaitForActionTimeout;
using base::test::ios::WaitUntilConditionOrTimeout;
using chrome_test_util::BrowserCommandDispatcherForMainBVC;

@implementation ChromeEarlGreyAppInterface

+ (NSError*)clearBrowsingHistory {
  if (chrome_test_util::ClearBrowsingHistory()) {
    return nil;
  }

  return testing::NSErrorWithLocalizedDescription(
      @"Clearing browser history timed out");
}

+ (void)startLoadingURL:(NSString*)URL {
  chrome_test_util::LoadUrl(GURL(base::SysNSStringToUTF8(URL)));
}

+ (BOOL)waitForWindowIDInjectionIfNeeded {
  web::WebState* webState = chrome_test_util::GetCurrentWebState();

  if (webState->ContentIsHTML()) {
    return web::WaitUntilWindowIdInjected(webState);
  }

  return YES;
}

+ (bool)isLoading {
  return chrome_test_util::IsLoading();
}

+ (void)startReloading {
  [BrowserCommandDispatcherForMainBVC() reload];
}

+ (void)openNewTab {
  chrome_test_util::OpenNewTab();
}

+ (void)closeCurrentTab {
  chrome_test_util::CloseCurrentTab();
}

+ (void)openNewIncognitoTab {
  chrome_test_util::OpenNewIncognitoTab();
}

+ (void)closeAllTabsInCurrentMode {
  chrome_test_util::CloseAllTabsInCurrentMode();
}

+ (BOOL)closeAllIncognitoTabs {
  return chrome_test_util::CloseAllIncognitoTabs();
}

+ (void)closeAllTabs {
  chrome_test_util::CloseAllTabs();
}

+ (void)startGoingBack {
  [BrowserCommandDispatcherForMainBVC() goBack];
}

+ (void)startGoingForward {
  [BrowserCommandDispatcherForMainBVC() goForward];
}

#pragma mark - WebState Utilities (EG2)

+ (NSError*)waitForWebStateContainingElement:(ElementSelector*)selector {
  bool success = WaitUntilConditionOrTimeout(kWaitForPageLoadTimeout, ^bool {
    return web::test::IsWebViewContainingElement(
        chrome_test_util::GetCurrentWebState(), selector);
  });
  if (!success) {
    NSString* NSErrorDescription = [NSString
        stringWithFormat:@"Failed waiting for web state containing element %@",
                         selector.selectorDescription];
    return testing::NSErrorWithLocalizedDescription(NSErrorDescription);
  }
  return nil;
}

+ (NSError*)waitForWebStateNotContainingText:(NSString*)text {
  bool success = WaitUntilConditionOrTimeout(kWaitForPageLoadTimeout, ^bool {
    return !web::test::IsWebViewContainingText(
        chrome_test_util::GetCurrentWebState(), base::SysNSStringToUTF8(text));
  });
  if (!success) {
    NSString* NSErrorDescription = [NSString
        stringWithFormat:@"Failed waiting for web view not containing %@",
                         text];
    return testing::NSErrorWithLocalizedDescription(NSErrorDescription);
  }
  return nil;
}

+ (NSUInteger)mainTabCount {
  return chrome_test_util::GetMainTabCount();
}

+ (NSUInteger)incognitoTabCount {
  return chrome_test_util::GetIncognitoTabCount();
}

+ (void)setContentSettings:(ContentSetting)setting {
  chrome_test_util::SetContentSettingsBlockPopups(setting);
}

+ (NSError*)signOutAndClearAccounts {
  bool success = chrome_test_util::SignOutAndClearAccounts();
  if (!success) {
    return testing::NSErrorWithLocalizedDescription(
        @"Real accounts couldn't be cleared.");
  }
  return nil;
}

+ (void)clearAutofillProfileWithGUID:(NSString*)GUID {
  std::string utfGUID = base::SysNSStringToUTF8(GUID);
  chrome_test_util::ClearAutofillProfile(utfGUID);
}

+ (void)injectAutofillProfileOnFakeSyncServerWithGUID:(NSString*)GUID
                                  autofillProfileName:(NSString*)fullName {
  std::string utfGUID = base::SysNSStringToUTF8(GUID);
  std::string utfFullName = base::SysNSStringToUTF8(fullName);
  chrome_test_util::InjectAutofillProfileOnFakeSyncServer(utfGUID, utfFullName);
}

+ (BOOL)isAutofillProfilePresentWithGUID:(NSString*)GUID
                     autofillProfileName:(NSString*)fullName {
  std::string utfGUID = base::SysNSStringToUTF8(GUID);
  std::string utfFullName = base::SysNSStringToUTF8(fullName);
  return chrome_test_util::IsAutofillProfilePresent(utfGUID, utfFullName);
}

+ (void)setUpFakeSyncServer {
  chrome_test_util::SetUpFakeSyncServer();
}

+ (void)tearDownFakeSyncServer {
  chrome_test_util::TearDownFakeSyncServer();
}

#pragma mark - Bookmarks Utilities (EG2)

+ (NSError*)waitForBookmarksToFinishinLoading {
  bool success = WaitUntilConditionOrTimeout(kWaitForActionTimeout, ^{
    return chrome_test_util::BookmarksLoaded();
  });
  if (!success) {
    return testing::NSErrorWithLocalizedDescription(
        @"Bookmark model did not load");
  }
  return nil;
}

+ (NSError*)clearBookmarks {
  bool success = chrome_test_util::ClearBookmarks();
  if (!success) {
    return testing::NSErrorWithLocalizedDescription(
        @"Not all bookmarks were removed.");
  }
  return nil;
}

@end
