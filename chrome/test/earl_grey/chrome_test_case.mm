// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/test/earl_grey/chrome_test_case.h"

#import <objc/runtime.h>

#include <memory>

#include "base/command_line.h"
#include "base/ios/ios_util.h"
#include "base/strings/sys_string_conversions.h"
#import "ios/chrome/test/earl_grey/chrome_earl_grey.h"
#import "ios/chrome/test/earl_grey/chrome_earl_grey_app_interface.h"
#import "ios/chrome/test/earl_grey/chrome_test_case_app_interface.h"
#import "ios/testing/earl_grey/app_launch_manager.h"
#import "ios/testing/earl_grey/earl_grey_test.h"
#include "net/test/embedded_test_server/default_handlers.h"
#include "net/test/embedded_test_server/embedded_test_server.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

namespace {

// This flag indicates whether +setUpForTestCase has been executed in a test
// case.
bool gExecutedSetUpForTestCase = false;

bool gIsMockAuthenticationDisabled = false;

NSString* const kFlakyEarlGreyTestTargetSuffix =
    @"_flaky_eg2tests_module-Runner";
NSString* const kMultitaskingEarlGreyTestTargetName =
    @"ios_chrome_multitasking_eg2tests_module-Runner";

// Contains a list of test names that run in multitasking test suite.
NSArray* multitaskingTests = @[
  // Integration tests
  @"testContextMenuOpenInNewTab",        // ContextMenuTestCase
  @"testContextMenuOpenInNewWindow",     // ContextMenuTestCase
  @"testSwitchToMain",                   // CookiesTestCase
  @"testSwitchToIncognito",              // CookiesTestCase
  @"testFindDefaultFormAssistControls",  // FormInputTestCase
  @"testTabDeletion",                    // TabUsageRecorderTestCase
  @"testAutoTranslate",                  // TranslateTestCase

  // Settings tests
  @"testSignInPopUpAccountOnSyncSettings",   // AccountCollectionsTestCase
  @"testAutofillProfileEditing",             // AutofillSettingsTestCase
  @"testAccessibilityOfBlockPopupSettings",  // BlockPopupsTestCase
  @"testClearCookies",                       // SettingsTestCase
  @"testAccessibilityOfTranslateSettings",   // TranslateUITestCase

  // UI tests
  @"testActivityServiceControllerPrintAfterRedirectionToUnprintablePage",
  // ActivityServiceControllerTestCase
  @"testDismissOnDestroy",           // AlertCoordinatorTestCase
  @"testAddRemoveBookmark",          // BookmarksTestCase
  @"testJavaScriptInOmnibox",        // BrowserViewControllerTestCase
  @"testChooseCastReceiverChooser",  // CastReceiverTestCase
  @"testErrorPage",                  // ErrorPageTestCase
  @"testFindInPage",                 // FindInPageTestCase
  @"testDismissFirstRun",            // FirstRunTestCase
  // TODO(crbug.com/872788) Failing after move to Xcode 10.
  // @"testLongPDFScroll",                         // FullscreenTestCase
  @"testDeleteHistory",                         // HistoryUITestCase
  @"testInfobarsDismissOnNavigate",             // InfobarTestCase
  @"testShowJavaScriptAlert",                   // JavaScriptDialogTestCase
  @"testKeyboardCommands_RecentTabsPresented",  // KeyboardCommandsTestCase
  @"testAccessibilityOnMostVisited",            // NewTabPageTestCase
  @"testPrintNormalPage",                       // PrintControllerTestCase
  @"testQRScannerUIIsShown",                 // QRScannerViewControllerTestCase
  @"testMarkMixedEntriesRead",               // ReadingListTestCase
  @"testClosedTabAppearsInRecentTabsPanel",  // RecentTabsTableTestCase
  @"testSafeModeSendingCrashReport",         // SafeModeTestCase
  @"testSignInOneUser",          // SigninInteractionControllerTestCase
  @"testSwitchTabs",             // StackViewTestCase
  @"testTabStripSwitchTabs",     // TabStripTestCase
  @"testTabHistoryMenu",         // TabHistoryPopupControllerTestCase
  @"testEnteringTabSwitcher",    // TabSwitcherControllerTestCase
  @"testEnterURL",               // ToolbarTestCase
  @"testOpenAndCloseToolsMenu",  // ToolsPopupMenuTestCase
  @"testUserFeedbackPageOpenPrivacyPolicy",  // UserFeedbackTestCase
  @"testVersion",                            // WebUITestCase
];

const CFTimeInterval kDrainTimeout = 5;

bool IsMockAuthenticationSetUp() {
  // |SetUpMockAuthentication| enables the fake sync server so checking
  // |isFakeSyncServerSetUp| here is sufficient to determine mock authentication
  // state.
  return [ChromeEarlGreyAppInterface isFakeSyncServerSetUp];
}

void SetUpMockAuthentication() {
  [ChromeTestCaseAppInterface setUpMockAuthentication];
}

void TearDownMockAuthentication() {
  [ChromeTestCaseAppInterface tearDownMockAuthentication];
}

void ResetAuthentication() {
  [ChromeTestCaseAppInterface resetAuthentication];
}

void RemoveInfoBarsAndPresentedState() {
  [ChromeTestCaseAppInterface removeInfoBarsAndPresentedState];
}
}  // namespace

GREY_STUB_CLASS_IN_APP_MAIN_QUEUE(ChromeTestCaseAppInterface)

@interface ChromeTestCase () <AppLaunchManagerObserver> {
  // Block to be executed during object tearDown.
  ProceduralBlock _tearDownHandler;

  // This flag indicates whether test method -setUp steps are executed during a
  // test method.
  BOOL _executedTestMethodSetUp;

  std::unique_ptr<net::EmbeddedTestServer> _testServer;

  // The orientation of the device when entering these tests.
  UIDeviceOrientation _originalOrientation;
}

// Cleans up mock authentication.
+ (void)disableMockAuthentication;

// Sets up mock authentication.
+ (void)enableMockAuthentication;

// Returns a NSArray of test names in this class that contain the prefix
// "FLAKY_".
+ (NSArray*)flakyTestNames;

// Returns a NSArray of test names in this class for multitasking test suite.
+ (NSArray*)multitaskingTestNames;
@end

@implementation ChromeTestCase

// Overrides testInvocations so the set of tests run can be modified, as
// necessary.
+ (NSArray*)testInvocations {

  // Return specific list of tests based on the target.
  NSString* targetName = [NSBundle mainBundle].infoDictionary[@"CFBundleName"];
  if ([targetName hasSuffix:kFlakyEarlGreyTestTargetSuffix]) {
    // Only run FLAKY_ tests for flaky test suites.
    return [self flakyTestNames];
  } else if ([targetName isEqualToString:kMultitaskingEarlGreyTestTargetName]) {
    // Only run white listed tests for the multitasking test suite.
    return [self multitaskingTestNames];
  } else {
    return [super testInvocations];
  }
}

+ (void)setUpForTestCase {
  [super setUpForTestCase];
  [ChromeTestCase setUpHelper];
  gExecutedSetUpForTestCase = true;
}

// Tear down called once for the class, to shutdown mock authentication.
+ (void)tearDown {
  [[self class] disableMockAuthentication];
  [super tearDown];
  gExecutedSetUpForTestCase = false;
}

- (net::EmbeddedTestServer*)testServer {
  if (!_testServer) {
    _testServer = std::make_unique<net::EmbeddedTestServer>();
    NSString* bundlePath = [NSBundle bundleForClass:[self class]].resourcePath;
    _testServer->ServeFilesFromDirectory(
        base::FilePath(base::SysNSStringToUTF8(bundlePath))
            .AppendASCII("ios/testing/data/http_server_files/"));
    net::test_server::RegisterDefaultHandlers(_testServer.get());
  }
  return _testServer.get();
}

// Set up called once per test, to open a new tab.
- (void)setUp {
  // Add this class as an AppLaunchManager observer before [super setUp],
  // as [super setUp] can trigger an app launch.
  [[AppLaunchManager sharedManager] addObserver:self];

  [super setUp];
  [self resetAppState];

  ResetAuthentication();

  // Reset any remaining sign-in state from previous tests.
  [ChromeEarlGrey signOutAndClearIdentities];
  [ChromeEarlGrey openNewTab];
  _executedTestMethodSetUp = YES;
}

// Tear down called once per test, to close all tabs and menus, and clear the
// tracked tests accounts. It also makes sure mock authentication is running.
- (void)tearDown {
  [[AppLaunchManager sharedManager] removeObserver:self];

  if (_tearDownHandler) {
    _tearDownHandler();
  }

  // Clear any remaining test accounts and signed in users.
  [ChromeEarlGrey signOutAndClearIdentities];

  [[self class] enableMockAuthentication];

  // Clean up any UI that may remain open so the next test starts in a clean
  // state.
  [[self class] removeAnyOpenMenusAndInfoBars];
  [[self class] closeAllTabs];

  if ([[GREY_REMOTE_CLASS_IN_APP(UIDevice) currentDevice] orientation] !=
      _originalOrientation) {
    // Rotate the device back to the original orientation, since some tests
    // attempt to run in other orientations.
    [ChromeEarlGrey rotateDeviceToOrientation:_originalOrientation error:nil];
  }
  [super tearDown];
  _executedTestMethodSetUp = NO;
}

#pragma mark - Public methods

- (void)setTearDownHandler:(ProceduralBlock)tearDownHandler {
  // Enforce that only one |_tearDownHandler| is set per test.
  DCHECK(!_tearDownHandler);
  _tearDownHandler = [tearDownHandler copy];
}

+ (void)removeAnyOpenMenusAndInfoBars {
  RemoveInfoBarsAndPresentedState();
  // After programatically removing UI elements, allow Earl Grey's
  // UI synchronization to become idle, so subsequent steps won't start before
  // the UI is in a good state.
  [[GREYUIThreadExecutor sharedInstance]
      drainUntilIdleWithTimeout:kDrainTimeout];
}

+ (void)closeAllTabs {
  [ChromeEarlGrey closeAllTabs];
  [[GREYUIThreadExecutor sharedInstance]
      drainUntilIdleWithTimeout:kDrainTimeout];
}

- (void)disableMockAuthentication {
  [[self class] disableMockAuthentication];
}

- (void)enableMockAuthentication {
  [[self class] enableMockAuthentication];
}

- (BOOL)isRunningTest:(SEL)selector {
  return [[self currentTestMethodName] isEqual:NSStringFromSelector(selector)];
}

#pragma mark - Private methods

+ (void)disableMockAuthentication {
  if (!IsMockAuthenticationSetUp()) {
    return;
  }
  gIsMockAuthenticationDisabled = YES;

  // Make sure local data is cleared, before disabling mock authentication,
  // where data may be sent to real servers.
  [ChromeEarlGrey signOutAndClearIdentities];
  [ChromeEarlGrey tearDownFakeSyncServer];
  TearDownMockAuthentication();
}

+ (void)enableMockAuthentication {
  if (IsMockAuthenticationSetUp()) {
    return;
  }
  gIsMockAuthenticationDisabled = NO;

  SetUpMockAuthentication();
  [ChromeEarlGrey setUpFakeSyncServer];
}

+ (NSArray*)flakyTestNames {
  const char kFlakyTestPrefix[] = "FLAKY";
  unsigned int count = 0;
  Method* methods = class_copyMethodList(self, &count);
  NSMutableArray* flakyTestNames = [NSMutableArray array];
  for (unsigned int i = 0; i < count; i++) {
    SEL selector = method_getName(methods[i]);
    if (std::string(sel_getName(selector)).find(kFlakyTestPrefix) == 0) {
      NSMethodSignature* methodSignature =
          [self instanceMethodSignatureForSelector:selector];
      NSInvocation* invocation =
          [NSInvocation invocationWithMethodSignature:methodSignature];
      invocation.selector = selector;
      [flakyTestNames addObject:invocation];
    }
  }
  free(methods);
  return flakyTestNames;
}

+ (NSArray*)multitaskingTestNames {
  unsigned int count = 0;
  Method* methods = class_copyMethodList(self, &count);
  NSMutableArray* multitaskingTestNames = [NSMutableArray array];
  for (unsigned int i = 0; i < count; i++) {
    SEL selector = method_getName(methods[i]);
    if ([multitaskingTests
            containsObject:base::SysUTF8ToNSString(sel_getName(selector))]) {
      NSMethodSignature* methodSignature =
          [self instanceMethodSignatureForSelector:selector];
      NSInvocation* invocation =
          [NSInvocation invocationWithMethodSignature:methodSignature];
      invocation.selector = selector;
      [multitaskingTestNames addObject:invocation];
    }
  }
  free(methods);
  return multitaskingTestNames;
}

// Called from +setUp or when the host app is relaunched.
// Dismisses and revert browser settings to default.
// It also enables mock authentication.
+ (void)setUpHelper {
  GREYAssertTrue([ChromeEarlGrey isCustomWebKitLoadedIfRequested],
                 @"Unable to load custom WebKit");

  [[self class] enableMockAuthentication];

  // Sometimes on start up there can be infobars (e.g. restore session), so
  // ensure the UI is in a clean state.
  [self removeAnyOpenMenusAndInfoBars];
  [self closeAllTabs];
  [ChromeEarlGrey setContentSettings:CONTENT_SETTING_DEFAULT];

  // Enforce the assumption that the tests are runing in portrait.
  [ChromeEarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortrait
                                      error:nil];
}

// Resets the application state.
// Called at the start of a test and when the app is relaunched.
- (void)resetAppState {
  [[self class] disableMockAuthentication];
  [[self class] enableMockAuthentication];

  gIsMockAuthenticationDisabled = NO;
  _tearDownHandler = nil;
  _originalOrientation =
      [[GREY_REMOTE_CLASS_IN_APP(UIDevice) currentDevice] orientation];
}

// Returns the method name, e.g. "testSomething" of the test that is currently
// running. The name is extracted from the string for the test's name property,
// e.g. "-[DemographicsTestCase testSomething]".
- (NSString*)currentTestMethodName {
  int testNameStart = [self.name rangeOfString:@"test"].location;
  return [self.name
      substringWithRange:NSMakeRange(testNameStart,
                                     self.name.length - testNameStart - 1)];
}

#pragma mark - Handling system alerts

- (void)failAllTestsDueToSystemAlertVisible {
  XCTFail("System alerts are present on device. Skipping all tests.");
}

#pragma mark AppLaunchManagerObserver method

- (void)appLaunchManagerDidRelaunchApp:(AppLaunchManager*)appLaunchManager
                             runResets:(BOOL)runResets {
  if (!runResets) {
    // Check stored flags and restore to app status before relaunch.
    if (!gIsMockAuthenticationDisabled) {
      [[self class] enableMockAuthentication];
    }
    return;
  }
  // Do not call +[ChromeTestCase setUpHelper] if the app was relaunched
  // before +setUpForTestCase. +setUpForTestCase will call +setUpHelper, and
  // +setUpHelper can not be called twice during setup process.
  if (gExecutedSetUpForTestCase) {
    [ChromeTestCase setUpHelper];

    // Do not call test method setup steps if the app was relaunched before
    // -setUp is executed. If do so, two new tabs will be opened before test
    // method starts.
    if (_executedTestMethodSetUp) {
      [self resetAppState];

      ResetAuthentication();

      // Reset any remaining sign-in state from previous tests.
      [ChromeEarlGrey signOutAndClearIdentities];
      [ChromeEarlGrey openNewTab];
    }
  }
}

@end
