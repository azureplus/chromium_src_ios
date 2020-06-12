// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/ui/page_info/page_info_coordinator.h"

#include "components/content_settings/core/common/features.h"
#include "ios/chrome/browser/browser_state/chrome_browser_state.h"
#include "ios/chrome/browser/content_settings/host_content_settings_map_factory.h"
#include "ios/chrome/browser/main/browser.h"
#import "ios/chrome/browser/reading_list/offline_page_tab_helper.h"
#include "ios/chrome/browser/ui/commands/browser_commands.h"
#import "ios/chrome/browser/ui/commands/command_dispatcher.h"
#import "ios/chrome/browser/ui/page_info/page_info_cookies_commands.h"
#import "ios/chrome/browser/ui/page_info/page_info_cookies_mediator.h"
#import "ios/chrome/browser/ui/page_info/page_info_site_security_description.h"
#import "ios/chrome/browser/ui/page_info/page_info_site_security_mediator.h"
#import "ios/chrome/browser/ui/page_info/page_info_view_controller.h"
#import "ios/chrome/browser/ui/settings/privacy/cookies_coordinator.h"
#import "ios/chrome/browser/ui/table_view/table_view_navigation_controller.h"
#include "ios/chrome/browser/ui/ui_feature_flags.h"
#import "ios/chrome/browser/web_state_list/web_state_list.h"
#include "ios/web/public/navigation/navigation_item.h"
#include "ios/web/public/navigation/navigation_manager.h"
#import "ios/web/public/web_state.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

@interface PageInfoCoordinator () <PageInfoCookiesCommands,
                                   PrivacyCookiesCoordinatorDelegate>

@property(nonatomic, strong)
    TableViewNavigationController* navigationController;
@property(nonatomic, strong) CommandDispatcher* dispatcher;
@property(nonatomic, strong) PageInfoViewController* viewController;
@property(nonatomic, strong) PageInfoCookiesMediator* cookiesMediator;
@property(nonatomic, strong) PrivacyCookiesCoordinator* cookiesCoordinator;

@end

@implementation PageInfoCoordinator

@synthesize presentationProvider = _presentationProvider;

#pragma mark - ChromeCoordinator

- (void)start {
  self.dispatcher = self.browser->GetCommandDispatcher();
  [self.dispatcher startDispatchingToTarget:self
                                forProtocol:@protocol(PageInfoCookiesCommands)];
  web::WebState* webState =
      self.browser->GetWebStateList()->GetActiveWebState();
  web::NavigationItem* navItem =
      webState->GetNavigationManager()->GetVisibleItem();

  bool offlinePage =
      OfflinePageTabHelper::FromWebState(webState)->presenting_offline_page();

  PageInfoSiteSecurityDescription* siteSecurityDescription =
      [PageInfoSiteSecurityMediator configurationForURL:navItem->GetURL()
                                              SSLStatus:navItem->GetSSL()
                                            offlinePage:offlinePage];
  if (!siteSecurityDescription.isEmpty &&
      base::FeatureList::IsEnabled(content_settings::kImprovedCookieControls)) {
    self.cookiesMediator = [[PageInfoCookiesMediator alloc]
        initWithPrefService:self.browser->GetBrowserState()->GetPrefs()
                settingsMap:ios::HostContentSettingsMapFactory::
                                GetForBrowserState(
                                    self.browser->GetBrowserState())];
  }
  self.viewController = [[PageInfoViewController alloc]
      initWithSiteSecurityDescription:siteSecurityDescription
                   cookiesDescription:[self.cookiesMediator
                                              cookiesDescription]];

  self.cookiesMediator.consumer = self.viewController;

  self.navigationController =
      [[TableViewNavigationController alloc] initWithTable:self.viewController];

  self.dispatcher = self.browser->GetCommandDispatcher();
  self.viewController.handler =
      static_cast<id<BrowserCommands, PageInfoCookiesCommands>>(
          self.dispatcher);

  [self.baseViewController presentViewController:self.navigationController
                                        animated:YES
                                      completion:nil];
}

- (void)stop {
  [self.baseViewController.presentedViewController
      dismissViewControllerAnimated:YES
                         completion:nil];
  [self.dispatcher stopDispatchingToTarget:self];
  self.navigationController = nil;
  self.viewController = nil;
  self.cookiesMediator = nil;
  self.cookiesCoordinator = nil;
}

#pragma mark - PageInfoCookiesCommands

- (void)showCookiesSettingsPage {
  self.cookiesCoordinator = [[PrivacyCookiesCoordinator alloc]
      initWithBaseViewController:self.navigationController
                         browser:self.browser];
  self.cookiesCoordinator.delegate = self;
  [self.cookiesCoordinator start];
}

#pragma mark - PrivacyCookiesCoordinatorDelegate

- (void)dismissPrivacyCookiesCoordinatorViewController:
    (PrivacyCookiesCoordinator*)coordinator {
  DCHECK(self.cookiesCoordinator);
  DCHECK(self.cookiesCoordinator == coordinator);
  [self.baseViewController.presentedViewController
      dismissViewControllerAnimated:YES
                         completion:nil];
  [coordinator stop];
  self.cookiesCoordinator = nil;
}

@end
