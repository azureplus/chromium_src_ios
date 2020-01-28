// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/tabs/closing_web_state_observer.h"

#include "base/logging.h"
#include "base/strings/string_piece.h"
#include "components/sessions/core/tab_restore_service.h"
#include "components/sessions/ios/ios_live_tab.h"
#include "components/sessions/ios/ios_restore_live_tab.h"
#include "ios/chrome/browser/chrome_url_constants.h"
#import "ios/chrome/browser/snapshots/snapshot_tab_helper.h"
#import "ios/chrome/browser/web_state_list/web_state_list.h"
#import "ios/web/public/navigation/navigation_item.h"
#import "ios/web/public/navigation/navigation_manager.h"
#import "ios/web/public/web_state.h"
#include "url/gurl.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

@implementation ClosingWebStateObserver {
  sessions::TabRestoreService* _restoreService;
}

- (instancetype)initWithRestoreService:
    (sessions::TabRestoreService*)restoreService {
  self = [super init];
  if (self) {
    _restoreService = restoreService;
  }
  return self;
}

#pragma mark - WebStateListObserving

- (void)webStateList:(WebStateList*)webStateList
    didReplaceWebState:(web::WebState*)oldWebState
          withWebState:(web::WebState*)newWebState
               atIndex:(int)atIndex {
  SnapshotTabHelper::FromWebState(oldWebState)->RemoveSnapshot();
}

- (void)webStateList:(WebStateList*)webStateList
    willDetachWebState:(web::WebState*)webState
               atIndex:(int)atIndex {
  [self recordHistoryForWebState:webState atIndex:atIndex];
}

- (void)webStateList:(WebStateList*)webStateList
    willCloseWebState:(web::WebState*)webState
              atIndex:(int)atIndex
           userAction:(BOOL)userAction {
  if (userAction) {
    SnapshotTabHelper::FromWebState(webState)->RemoveSnapshot();
  }
}

#pragma mark - Private

- (void)recordHistoryForWebState:(web::WebState*)webState atIndex:(int)atIndex {
  // The RestoreService will be null if navigation is off the record.
  if (!_restoreService)
    return;

  web::NavigationManager* navigationManager = webState->GetNavigationManager();
  if (navigationManager->IsRestoreSessionInProgress()) {
    auto live_tab = std::make_unique<sessions::RestoreIOSLiveTab>(
        webState->BuildSessionStorage());
    _restoreService->CreateHistoricalTab(live_tab.get(), atIndex);
    return;
  }
  // No need to record history if the tab has no navigation or has only
  // presented the NTP or the bookmark UI.
  if (navigationManager->GetItemCount() <= 1) {
    web::NavigationItem* item = navigationManager->GetLastCommittedItem();
    if (!item)
      return;

    const base::StringPiece host = item->GetVirtualURL().host_piece();
    if (host == kChromeUINewTabHost)
      return;
  }

  _restoreService->CreateHistoricalTab(
      sessions::IOSLiveTab::GetForWebState(webState), atIndex);
}

@end