// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ios/chrome/app/application_delegate/user_activity_handler.h"

#include <memory>

#import <CoreSpotlight/CoreSpotlight.h>

#include "base/ios/ios_util.h"
#include "base/mac/scoped_block.h"
#include "base/strings/stringprintf.h"
#include "base/strings/sys_string_conversions.h"
#include "base/test/scoped_command_line.h"
#include "components/handoff/handoff_utility.h"
#include "ios/chrome/app/application_delegate/fake_startup_information.h"
#include "ios/chrome/app/application_delegate/mock_tab_opener.h"
#include "ios/chrome/app/application_delegate/startup_information.h"
#include "ios/chrome/app/application_delegate/tab_opening.h"
#include "ios/chrome/app/application_mode.h"
#include "ios/chrome/app/main_controller.h"
#include "ios/chrome/app/spotlight/actions_spotlight_manager.h"
#import "ios/chrome/app/spotlight/spotlight_util.h"
#include "ios/chrome/browser/app_startup_parameters.h"
#include "ios/chrome/browser/chrome_switches.h"
#include "ios/chrome/browser/chrome_url_constants.h"
#import "ios/chrome/browser/tabs/legacy_tab_helper.h"
#import "ios/chrome/browser/tabs/tab.h"
#import "ios/chrome/browser/tabs/tab_model.h"
#import "ios/chrome/browser/tabs/tab_model_observer.h"
#import "ios/chrome/browser/u2f/u2f_controller.h"
#import "ios/chrome/browser/web/tab_id_tab_helper.h"
#import "ios/chrome/browser/web_state_list/fake_web_state_list_delegate.h"
#import "ios/chrome/browser/web_state_list/web_state_list.h"
#import "ios/chrome/browser/web_state_list/web_state_opener.h"
#import "ios/chrome/test/base/scoped_block_swizzler.h"
#import "ios/web/public/test/fakes/test_web_state.h"
#import "net/base/mac/url_conversions.h"
#include "net/test/gtest_util.h"
#include "testing/platform_test.h"
#import "third_party/ocmock/OCMock/OCMock.h"
#include "third_party/ocmock/gtest_support.h"
#include "ui/base/page_transition_types.h"
#include "url/gurl.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#pragma mark - Tab Mock

// Tab mock for using in UserActivity tests.
@interface UserActivityHandlerTabMock : NSObject

@property(nonatomic, readonly) GURL url;
@property(nonatomic, readonly) NSString* tabId;

- (instancetype)initWithWebState:(web::WebState*)webState
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

@implementation UserActivityHandlerTabMock {
  web::WebState* _webState;
}

@synthesize url = _url;

- (instancetype)initWithWebState:(web::WebState*)webState {
  if ((self = [super init])) {
    DCHECK(webState);
    _webState = webState;
  }
  return self;
}

- (void)evaluateU2FResultFromURL:(const GURL&)url {
  _url = url;
}

- (NSString*)tabId {
  DCHECK(_webState);
  return TabIdTabHelper::FromWebState(_webState)->tab_id();
}

@end

#pragma mark - TabModel Mock

// TabModel mock for using in UserActivity tests.
@interface UserActivityHandlerTabModelMock : NSObject

@end

@implementation UserActivityHandlerTabModelMock {
  FakeWebStateListDelegate _webStateListDelegate;
  std::unique_ptr<WebStateList> _webStateList;
}

- (instancetype)init {
  if ((self = [super init])) {
    _webStateList = std::make_unique<WebStateList>(&_webStateListDelegate);
  }
  return self;
}

- (UserActivityHandlerTabMock*)addMockTab {
  auto testWebState = std::make_unique<web::TestWebState>();
  TabIdTabHelper::CreateForWebState(testWebState.get());

  UserActivityHandlerTabMock* tab =
      [[UserActivityHandlerTabMock alloc] initWithWebState:testWebState.get()];
  LegacyTabHelper::CreateForWebStateForTesting(testWebState.get(),
                                               static_cast<Tab*>(tab));

  _webStateList->InsertWebState(0, std::move(testWebState),
                                WebStateList::INSERT_NO_FLAGS,
                                WebStateOpener());

  return tab;
}

- (WebStateList*)webStateList {
  return _webStateList.get();
}

@end

#pragma mark - Test class.

// A block that takes as arguments the caller and the arguments from
// UserActivityHandler +handleStartupParameters and returns nothing.
typedef void (^startupParameterBlock)(id,
                                      id<TabOpening>,
                                      id<StartupInformation>,
                                      id<BrowserViewInformation>);

// A block that takes a BOOL argument and returns nothing.
typedef void (^conditionBlock)(BOOL);

class UserActivityHandlerTest : public PlatformTest {
 protected:
  void swizzleHandleStartupParameters() {
    handle_startup_parameters_has_been_called_ = NO;
    swizzle_block_ = [^(id self) {
      handle_startup_parameters_has_been_called_ = YES;
    } copy];
    user_activity_handler_swizzler_.reset(new ScopedBlockSwizzler(
        [UserActivityHandler class],
        @selector(handleStartupParametersWithTabOpener:
                                    startupInformation:
                                browserViewInformation:),
        swizzle_block_));
  }

  BOOL getHandleStartupParametersHasBeenCalled() {
    return handle_startup_parameters_has_been_called_;
  }

  void resetHandleStartupParametersHasBeenCalled() {
    handle_startup_parameters_has_been_called_ = NO;
  }

  conditionBlock getCompletionHandler() {
    if (!completion_block_) {
      block_executed_ = NO;
      completion_block_ = [^(BOOL arg) {
        block_executed_ = YES;
        block_argument_ = arg;
      } copy];
    }
    return completion_block_;
  }

  BOOL completionHandlerExecuted() { return block_executed_; }

  BOOL completionHandlerArgument() { return block_argument_; }

 private:
  __block BOOL block_executed_;
  __block BOOL block_argument_;
  std::unique_ptr<ScopedBlockSwizzler> user_activity_handler_swizzler_;
  startupParameterBlock swizzle_block_;
  conditionBlock completion_block_;
  __block BOOL handle_startup_parameters_has_been_called_;
};

#pragma mark - Tests.

using UserActivityHandlerNoFixtureTest = PlatformTest;

// Tests that Chrome notifies the user if we are passing a correct
// userActivityType.
TEST_F(UserActivityHandlerNoFixtureTest,
       willContinueUserActivityCorrectActivity) {
  EXPECT_TRUE([UserActivityHandler
      willContinueUserActivityWithType:handoff::kChromeHandoffActivityType]);

  if (spotlight::IsSpotlightAvailable()) {
    EXPECT_TRUE([UserActivityHandler
        willContinueUserActivityWithType:CSSearchableItemActionType]);
  }
}

// Tests that Chrome does not notifies the user if we are passing an incorrect
// userActivityType.
TEST_F(UserActivityHandlerNoFixtureTest,
       willContinueUserActivityIncorrectActivity) {
  EXPECT_FALSE([UserActivityHandler
      willContinueUserActivityWithType:[handoff::kChromeHandoffActivityType
                                           stringByAppendingString:@"test"]]);

  EXPECT_FALSE([UserActivityHandler
      willContinueUserActivityWithType:@"it.does.not.work"]);

  EXPECT_FALSE([UserActivityHandler willContinueUserActivityWithType:@""]);

  EXPECT_FALSE([UserActivityHandler willContinueUserActivityWithType:nil]);
}

using UserActivityHandlerNoFixtureTest = PlatformTest;

// Tests that Chrome does not continue the activity is the activity type is
// random.
TEST_F(UserActivityHandlerNoFixtureTest, continueUserActivityFromGarbage) {
  // Setup.
  NSString* handoffWithSuffix =
      [handoff::kChromeHandoffActivityType stringByAppendingString:@"test"];
  NSString* handoffWithPrefix =
      [@"test" stringByAppendingString:handoff::kChromeHandoffActivityType];
  NSArray* userActivityTypes = @[
    @"thisIsGarbage", @"it.does.not.work", handoffWithSuffix, handoffWithPrefix
  ];
  for (NSString* userActivityType in userActivityTypes) {
    NSUserActivity* userActivity =
        [[NSUserActivity alloc] initWithActivityType:userActivityType];
    [userActivity setWebpageURL:[NSURL URLWithString:@"http://www.google.com"]];

    // The test will fail is a method of those objects is called.
    id tabOpenerMock = [OCMockObject mockForProtocol:@protocol(TabOpening)];
    id startupInformationMock =
        [OCMockObject mockForProtocol:@protocol(StartupInformation)];

    // Action.
    BOOL result =
        [UserActivityHandler continueUserActivity:userActivity
                              applicationIsActive:NO
                                        tabOpener:tabOpenerMock
                               startupInformation:startupInformationMock];

    // Tests.
    EXPECT_FALSE(result);
  }
}

// Tests that Chrome does not continue the activity if the webpage url is not
// set.
TEST_F(UserActivityHandlerNoFixtureTest, continueUserActivityNoWebpage) {
  // Setup.
  NSUserActivity* userActivity = [[NSUserActivity alloc]
      initWithActivityType:handoff::kChromeHandoffActivityType];

  // The test will fail is a method of those objects is called.
  id tabOpenerMock = [OCMockObject mockForProtocol:@protocol(TabOpening)];
  id startupInformationMock =
      [OCMockObject mockForProtocol:@protocol(StartupInformation)];

  // Action.
  BOOL result =
      [UserActivityHandler continueUserActivity:userActivity
                            applicationIsActive:NO
                                      tabOpener:tabOpenerMock
                             startupInformation:startupInformationMock];

  // Tests.
  EXPECT_FALSE(result);
}

// Tests that Chrome does not continue the activity if the activity is a
// Spotlight action of an unknown type.
TEST_F(UserActivityHandlerNoFixtureTest,
       continueUserActivitySpotlightActionFromGarbage) {
  // Only test Spotlight if it is enabled and available on the device.
  if (!spotlight::IsSpotlightAvailable()) {
    return;
  }
  // Setup.
  NSUserActivity* userActivity =
      [[NSUserActivity alloc] initWithActivityType:CSSearchableItemActionType];
  NSString* invalidAction =
      [NSString stringWithFormat:@"%@.invalidAction",
                                 spotlight::StringFromSpotlightDomain(
                                     spotlight::DOMAIN_ACTIONS)];
  NSDictionary* userInfo =
      @{CSSearchableItemActivityIdentifier : invalidAction};
  [userActivity addUserInfoEntriesFromDictionary:userInfo];

  // Enable the SpotlightActions experiment.
  base::test::ScopedCommandLine scoped_command_line;
  scoped_command_line.GetProcessCommandLine()->AppendSwitch(
      switches::kEnableSpotlightActions);

  id tabOpenerMock = [OCMockObject mockForProtocol:@protocol(TabOpening)];
  id startupInformationMock =
      [OCMockObject mockForProtocol:@protocol(StartupInformation)];

  // Action.
  BOOL result =
      [UserActivityHandler continueUserActivity:userActivity
                            applicationIsActive:NO
                                      tabOpener:tabOpenerMock
                             startupInformation:startupInformationMock];

  // Tests.
  EXPECT_FALSE(result);
}

// Tests that Chrome continues the activity if the application is in background
// by saving the url to startupParameters.
TEST_F(UserActivityHandlerNoFixtureTest, continueUserActivityBackground) {
  // Setup.
  NSUserActivity* userActivity = [[NSUserActivity alloc]
      initWithActivityType:handoff::kChromeHandoffActivityType];
  NSURL* nsurl = [NSURL URLWithString:@"http://www.google.com"];
  [userActivity setWebpageURL:nsurl];

  id startupInformationMock =
      [OCMockObject niceMockForProtocol:@protocol(StartupInformation)];
  [[startupInformationMock expect]
      setStartupParameters:[OCMArg checkWithBlock:^BOOL(id value) {
        EXPECT_TRUE([value isKindOfClass:[AppStartupParameters class]]);

        AppStartupParameters* startupParameters = (AppStartupParameters*)value;
        const GURL calledURL = startupParameters.externalURL;
        return calledURL == net::GURLWithNSURL(nsurl);
      }]];

  // The test will fail is a method of this object is called.
  id tabOpenerMock = [OCMockObject mockForProtocol:@protocol(TabOpening)];

  // Action.
  BOOL result =
      [UserActivityHandler continueUserActivity:userActivity
                            applicationIsActive:NO
                                      tabOpener:tabOpenerMock
                             startupInformation:startupInformationMock];

  // Test.
  EXPECT_OCMOCK_VERIFY(startupInformationMock);
  EXPECT_TRUE(result);
}

// Tests that Chrome continues the activity if the application is in foreground
// by opening a new tab.
TEST_F(UserActivityHandlerNoFixtureTest, continueUserActivityForeground) {
  // Setup.
  NSUserActivity* userActivity = [[NSUserActivity alloc]
      initWithActivityType:handoff::kChromeHandoffActivityType];
  NSURL* nsurl = [NSURL URLWithString:@"http://www.google.com"];
  [userActivity setWebpageURL:nsurl];

  MockTabOpener* tabOpener = [[MockTabOpener alloc] init];

  id startupInformationMock =
      [OCMockObject mockForProtocol:@protocol(StartupInformation)];
  [[[startupInformationMock stub] andReturnValue:@NO] isPresentingFirstRunUI];

  AppStartupParameters* startupParams = [[AppStartupParameters alloc]
      initWithExternalURL:(GURL("http://www.google.com"))];
  [[[startupInformationMock stub] andReturn:startupParams] startupParameters];

  // Action.
  BOOL result =
      [UserActivityHandler continueUserActivity:userActivity
                            applicationIsActive:YES
                                      tabOpener:tabOpener
                             startupInformation:startupInformationMock];

  // Test.
  EXPECT_EQ(net::GURLWithNSURL(nsurl), [tabOpener url]);
  EXPECT_TRUE(result);
}

// Tests that a new tab is created when application is started via Universal
// Link.
TEST_F(UserActivityHandlerTest, continueUserActivityBrowsingWeb) {
  NSUserActivity* userActivity = [[NSUserActivity alloc]
      initWithActivityType:NSUserActivityTypeBrowsingWeb];
  // This URL is passed to application by iOS but is not used in this part
  // of application logic.
  NSURL* nsurl = [NSURL URLWithString:@"http://goo.gl/foo/bar"];
  [userActivity setWebpageURL:nsurl];

  MockTabOpener* tabOpener = [[MockTabOpener alloc] init];

  // Use an object to capture the startup paramters set by UserActivityHandler.
  FakeStartupInformation* fakeStartupInformation =
      [[FakeStartupInformation alloc] init];
  [fakeStartupInformation setIsPresentingFirstRunUI:NO];

  BOOL result =
      [UserActivityHandler continueUserActivity:userActivity
                            applicationIsActive:YES
                                      tabOpener:tabOpener
                             startupInformation:fakeStartupInformation];

  GURL newTabURL(kChromeUINewTabURL);
  EXPECT_EQ(newTabURL, [tabOpener url]);
  // AppStartupParameters default to opening pages in non-Incognito mode.
  EXPECT_EQ(ApplicationMode::NORMAL, [tabOpener applicationMode]);
  EXPECT_TRUE(result);
  // Verifies that a new tab is being requested.
  EXPECT_EQ(newTabURL,
            [[fakeStartupInformation startupParameters] externalURL]);
}

// Tests that continueUserActivity sets startupParameters accordingly to the
// Spotlight action used.
TEST_F(UserActivityHandlerTest, continueUserActivityShortcutActions) {
  // Only test Spotlight if it is enabled and available on the device.
  if (!spotlight::IsSpotlightAvailable()) {
    return;
  }
  // Setup.
  GURL gurlNewTab(kChromeUINewTabURL);
  FakeStartupInformation* fakeStartupInformation =
      [[FakeStartupInformation alloc] init];

  NSArray* parametersToTest = @[
    @[
      base::SysUTF8ToNSString(spotlight::kSpotlightActionNewTab), @(NO_ACTION)
    ],
    @[
      base::SysUTF8ToNSString(spotlight::kSpotlightActionNewIncognitoTab),
      @(NO_ACTION)
    ],
    @[
      base::SysUTF8ToNSString(spotlight::kSpotlightActionVoiceSearch),
      @(START_VOICE_SEARCH)
    ],
    @[
      base::SysUTF8ToNSString(spotlight::kSpotlightActionQRScanner),
      @(START_QR_CODE_SCANNER)
    ]
  ];

  // Enable the Spotlight Actions experiment.
  base::test::ScopedCommandLine scoped_command_line;
  scoped_command_line.GetProcessCommandLine()->AppendSwitch(
      switches::kEnableSpotlightActions);

  for (id parameters in parametersToTest) {
    NSUserActivity* userActivity = [[NSUserActivity alloc]
        initWithActivityType:CSSearchableItemActionType];
    NSString* action = [NSString
        stringWithFormat:@"%@.%@", spotlight::StringFromSpotlightDomain(
                                       spotlight::DOMAIN_ACTIONS),
                         parameters[0]];
    NSDictionary* userInfo = @{CSSearchableItemActivityIdentifier : action};
    [userActivity addUserInfoEntriesFromDictionary:userInfo];

    id tabOpenerMock = [OCMockObject mockForProtocol:@protocol(TabOpening)];

    // Action.
    BOOL result =
        [UserActivityHandler continueUserActivity:userActivity
                              applicationIsActive:NO
                                        tabOpener:tabOpenerMock
                               startupInformation:fakeStartupInformation];

    // Tests.
    EXPECT_TRUE(result);
    EXPECT_EQ(gurlNewTab,
              [fakeStartupInformation startupParameters].externalURL);
    EXPECT_EQ([parameters[1] intValue],
              [fakeStartupInformation startupParameters].postOpeningAction);
  }
}

// Tests that handleStartupParameters with a non-U2F url opens a new tab.
TEST_F(UserActivityHandlerNoFixtureTest, handleStartupParamsNonU2F) {
  // Setup.
  GURL gurl("http://www.google.com");

  AppStartupParameters* startupParams =
      [[AppStartupParameters alloc] initWithExternalURL:gurl];
  [startupParams setLaunchInIncognito:YES];

  id startupInformationMock =
      [OCMockObject mockForProtocol:@protocol(StartupInformation)];
  [[[startupInformationMock stub] andReturnValue:@NO] isPresentingFirstRunUI];
  [[[startupInformationMock stub] andReturn:startupParams] startupParameters];
  [[startupInformationMock expect] setStartupParameters:nil];

  MockTabOpener* tabOpener = [[MockTabOpener alloc] init];

  // The test will fail is a method of this object is called.
  id browserViewMock =
      [OCMockObject mockForProtocol:@protocol(BrowserViewInformation)];

  // Action.
  [UserActivityHandler
      handleStartupParametersWithTabOpener:tabOpener
                        startupInformation:startupInformationMock
                    browserViewInformation:browserViewMock];
  [tabOpener completionBlock]();

  // Tests.
  EXPECT_OCMOCK_VERIFY(startupInformationMock);
  EXPECT_EQ(gurl, [tabOpener url]);
  EXPECT_EQ(ApplicationMode::INCOGNITO, [tabOpener applicationMode]);
}

// Tests that handleStartupParameters with a U2F url opens in the correct tab.
TEST_F(UserActivityHandlerNoFixtureTest, handleStartupParamsU2F) {
  // Setup.
  UserActivityHandlerTabModelMock* tabModel =
      [[UserActivityHandlerTabModelMock alloc] init];
  UserActivityHandlerTabMock* tabMock = [tabModel addMockTab];

  std::string urlRepresentation =
      base::StringPrintf("chromium://u2f-callback?isU2F=1&tabID=%s",
                         base::SysNSStringToUTF8(tabMock.tabId).c_str());

  GURL gurl(urlRepresentation);
  AppStartupParameters* startupParams =
      [[AppStartupParameters alloc] initWithExternalURL:gurl];
  [startupParams setLaunchInIncognito:YES];

  id startupInformationMock =
      [OCMockObject mockForProtocol:@protocol(StartupInformation)];
  [[[startupInformationMock stub] andReturnValue:@NO] isPresentingFirstRunUI];
  [[[startupInformationMock stub] andReturn:startupParams] startupParameters];
  [[startupInformationMock expect] setStartupParameters:nil];

  id browserViewInformationMock =
      [OCMockObject mockForProtocol:@protocol(BrowserViewInformation)];
  [[[browserViewInformationMock stub] andReturn:(TabModel*)tabModel]
      mainTabModel];
  [[[browserViewInformationMock stub] andReturn:(TabModel*)tabModel]
      otrTabModel];

  MockTabOpener* tabOpener = [[MockTabOpener alloc] init];

  // Action.
  [UserActivityHandler
      handleStartupParametersWithTabOpener:tabOpener
                        startupInformation:startupInformationMock
                    browserViewInformation:browserViewInformationMock];

  // Tests.
  EXPECT_OCMOCK_VERIFY(startupInformationMock);
  EXPECT_EQ(gurl, [tabMock url]);
}

// Tests that performActionForShortcutItem set startupParameters accordingly to
// the shortcut used
TEST_F(UserActivityHandlerTest, performActionForShortcutItemWithRealShortcut) {
  // Setup.
  GURL gurlNewTab("chrome://newtab/");

  FakeStartupInformation* fakeStartupInformation =
      [[FakeStartupInformation alloc] init];
  [fakeStartupInformation setIsPresentingFirstRunUI:NO];

  NSArray* parametersToTest = @[
    @[ @"OpenNewTab", @NO, @(NO_ACTION) ],
    @[ @"OpenIncognitoTab", @YES, @(NO_ACTION) ],
    @[ @"OpenVoiceSearch", @NO, @(START_VOICE_SEARCH) ],
    @[ @"OpenQRScanner", @NO, @(START_QR_CODE_SCANNER) ]
  ];

  swizzleHandleStartupParameters();

  for (id parameters in parametersToTest) {
    UIApplicationShortcutItem* shortcut =
        [[UIApplicationShortcutItem alloc] initWithType:parameters[0]
                                         localizedTitle:parameters[0]];

    resetHandleStartupParametersHasBeenCalled();

    // The test will fail is a method of those objects is called.
    id tabOpenerMock = [OCMockObject mockForProtocol:@protocol(TabOpening)];
    id browserViewInformationMock =
        [OCMockObject mockForProtocol:@protocol(BrowserViewInformation)];

    // Action.
    [UserActivityHandler
        performActionForShortcutItem:shortcut
                   completionHandler:getCompletionHandler()
                           tabOpener:tabOpenerMock
                  startupInformation:fakeStartupInformation
              browserViewInformation:browserViewInformationMock];

    // Tests.
    EXPECT_EQ(gurlNewTab,
              [fakeStartupInformation startupParameters].externalURL);
    EXPECT_EQ([[parameters objectAtIndex:1] boolValue],
              [fakeStartupInformation startupParameters].launchInIncognito);
    EXPECT_EQ([[parameters objectAtIndex:2] intValue],
              [fakeStartupInformation startupParameters].postOpeningAction);
    EXPECT_TRUE(completionHandlerExecuted());
    EXPECT_TRUE(completionHandlerArgument());
    EXPECT_TRUE(getHandleStartupParametersHasBeenCalled());
  }
}

// Tests that performActionForShortcutItem just executes the completionHandler
// with NO if the firstRunUI is present.
TEST_F(UserActivityHandlerTest, performActionForShortcutItemWithFirstRunUI) {
  // Setup.
  id startupInformationMock =
      [OCMockObject mockForProtocol:@protocol(StartupInformation)];
  [[[startupInformationMock stub] andReturnValue:@YES] isPresentingFirstRunUI];

  UIApplicationShortcutItem* shortcut =
      [[UIApplicationShortcutItem alloc] initWithType:@"OpenNewTab"
                                       localizedTitle:@""];

  swizzleHandleStartupParameters();

  // The test will fail is a method of those objects is called.
  id tabOpenerMock = [OCMockObject mockForProtocol:@protocol(TabOpening)];
  id browserViewInformationMock =
      [OCMockObject mockForProtocol:@protocol(BrowserViewInformation)];

  // Action.
  [UserActivityHandler performActionForShortcutItem:shortcut
                                  completionHandler:getCompletionHandler()
                                          tabOpener:tabOpenerMock
                                 startupInformation:startupInformationMock
                             browserViewInformation:browserViewInformationMock];

  // Tests.
  EXPECT_TRUE(completionHandlerExecuted());
  EXPECT_FALSE(completionHandlerArgument());
  EXPECT_FALSE(getHandleStartupParametersHasBeenCalled());
}
