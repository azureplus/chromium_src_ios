// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <EarlGrey/EarlGrey.h>
#import <XCTest/XCTest.h>

#include "components/strings/grit/components_strings.h"
#import "ios/chrome/browser/ui/toolbar/adaptive/primary_toolbar_view.h"
#import "ios/chrome/browser/ui/toolbar/adaptive/secondary_toolbar_view.h"
#import "ios/chrome/browser/ui/toolbar/public/toolbar_controller_constants.h"
#include "ios/chrome/browser/ui/ui_util.h"
#import "ios/chrome/browser/ui/uikit_ui_util.h"
#import "ios/chrome/browser/ui/util/top_view_controller.h"
#include "ios/chrome/grit/ios_strings.h"
#include "ios/chrome/test/app/bookmarks_test_util.h"
#import "ios/chrome/test/app/chrome_test_util.h"
#import "ios/chrome/test/earl_grey/chrome_actions.h"
#import "ios/chrome/test/earl_grey/chrome_earl_grey.h"
#import "ios/chrome/test/earl_grey/chrome_matchers.h"
#import "ios/chrome/test/earl_grey/chrome_test_case.h"
#include "ios/testing/earl_grey/disabled_test_macros.h"
#import "ios/web/public/test/earl_grey/web_view_matchers.h"
#include "net/test/embedded_test_server/http_request.h"
#include "net/test/embedded_test_server/http_response.h"
#include "ui/base/l10n/l10n_util_mac.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

namespace {
const char kPageURL[] = "/test-page.html";
const char kPageURL2[] = "/test-page-2.html";
const char kPageURL3[] = "/test-page-3.html";
const char kLinkID[] = "linkID";
const char kPageLoadedString[] = "Page loaded!";

// Provides responses for redirect and changed window location URLs.
std::unique_ptr<net::test_server::HttpResponse> StandardResponse(
    const net::test_server::HttpRequest& request) {
  std::unique_ptr<net::test_server::BasicHttpResponse> http_response =
      std::make_unique<net::test_server::BasicHttpResponse>();
  http_response->set_code(net::HTTP_OK);
  http_response->set_content(
      "<html><body><p>" + std::string(kPageLoadedString) + "</p><a href=\"" +
      kPageURL3 + "\" id=\"" + kLinkID + "\">link!</a></body></html>");
  return std::move(http_response);
}

// Returns a matcher for the bookmark button.
id<GREYMatcher> BookmarkButton() {
  return chrome_test_util::ButtonWithAccessibilityLabelId(IDS_TOOLTIP_STAR);
}

// Returns a matcher for the visible share button.
id<GREYMatcher> ShareButton() {
  return grey_allOf(grey_accessibilityID(kToolbarShareButtonIdentifier),
                    grey_sufficientlyVisible(), nil);
}

// Returns a matcher for a UIResponder object being first responder.
id<GREYMatcher> firstResponder() {
  MatchesBlock matches = ^BOOL(UIResponder* responder) {
    return [responder isFirstResponder];
  };
  DescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:@"first responder"];
  };
  return grey_allOf(
      grey_kindOfClass([UIResponder class]),
      [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches
                                           descriptionBlock:describe],
      nil);
}

// Returns a matcher for elements being subviews of the PrimaryToolbarView and
// sufficientlyVisible.
id<GREYMatcher> VisibleInPrimaryToolbar() {
  return grey_allOf(grey_ancestor(grey_kindOfClass([PrimaryToolbarView class])),
                    grey_sufficientlyVisible(), nil);
}

// Returns a matcher for elements being subviews of the SecondaryToolbarView and
// sufficientlyVisible.
id<GREYMatcher> VisibleInSecondaryToolbar() {
  return grey_allOf(
      grey_ancestor(grey_kindOfClass([SecondaryToolbarView class])),
      grey_sufficientlyVisible(), nil);
}

// Check that the button displayed are the ones which should be displayed in the
// environment described by |traitCollection|.
void CheckToolbarButtonVisibility(UITraitCollection* traitCollection) {
  if (traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact &&
      traitCollection.verticalSizeClass != UIUserInterfaceSizeClassCompact) {
    // Split toolbar.

    // Test the visibility of the primary toolbar buttons.
    [[EarlGrey selectElementWithMatcher:chrome_test_util::BackButton()]
        assertWithMatcher:VisibleInPrimaryToolbar()];
    [[EarlGrey selectElementWithMatcher:chrome_test_util::ForwardButton()]
        assertWithMatcher:VisibleInPrimaryToolbar()];
    [[EarlGrey selectElementWithMatcher:chrome_test_util::Omnibox()]
        assertWithMatcher:VisibleInPrimaryToolbar()];

    // Test the visibility of the secondary toolbar buttons.
    [[EarlGrey selectElementWithMatcher:chrome_test_util::
                                            ButtonWithAccessibilityLabelId(
                                                IDS_IOS_TOOLBAR_SHOW_TABS)]
        assertWithMatcher:VisibleInSecondaryToolbar()];
    [[EarlGrey selectElementWithMatcher:ShareButton()]
        assertWithMatcher:VisibleInSecondaryToolbar()];
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(
                                            kToolbarOmniboxButtonIdentifier)]
        assertWithMatcher:VisibleInSecondaryToolbar()];
    [[EarlGrey selectElementWithMatcher:BookmarkButton()]
        assertWithMatcher:VisibleInSecondaryToolbar()];
    [[EarlGrey selectElementWithMatcher:chrome_test_util::
                                            ButtonWithAccessibilityLabelId(
                                                IDS_IOS_TOOLBAR_SETTINGS)]
        assertWithMatcher:VisibleInSecondaryToolbar()];
  } else {
    // Unsplit toolbar.

    // Test the visibility of the primary toolbar buttons.
    [[EarlGrey selectElementWithMatcher:chrome_test_util::BackButton()]
        assertWithMatcher:VisibleInPrimaryToolbar()];
    [[EarlGrey selectElementWithMatcher:chrome_test_util::ForwardButton()]
        assertWithMatcher:VisibleInPrimaryToolbar()];
    [[EarlGrey selectElementWithMatcher:chrome_test_util::Omnibox()]
        assertWithMatcher:VisibleInPrimaryToolbar()];
    [[EarlGrey selectElementWithMatcher:ShareButton()]
        assertWithMatcher:VisibleInPrimaryToolbar()];
    [[EarlGrey selectElementWithMatcher:BookmarkButton()]
        assertWithMatcher:VisibleInPrimaryToolbar()];
    [[EarlGrey selectElementWithMatcher:chrome_test_util::
                                            ButtonWithAccessibilityLabelId(
                                                IDS_IOS_TOOLBAR_SETTINGS)]
        assertWithMatcher:VisibleInPrimaryToolbar()];

    // The secondary toolbar is not visible.
    [[EarlGrey
        selectElementWithMatcher:grey_kindOfClass([SecondaryToolbarView class])]
        assertWithMatcher:grey_not(grey_sufficientlyVisible())];

    if (traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
      // Unsplit in compact height, the stack view button is visible.
      [[EarlGrey selectElementWithMatcher:chrome_test_util::
                                              ButtonWithAccessibilityLabelId(
                                                  IDS_IOS_TOOLBAR_SHOW_TABS)]
          assertWithMatcher:VisibleInPrimaryToolbar()];
    } else {
      // Unsplit in Regular x Regular, the reload/stop button is visible.
      [[EarlGrey selectElementWithMatcher:chrome_test_util::
                                              ButtonWithAccessibilityLabelId(
                                                  IDS_IOS_ACCNAME_RELOAD)]
          assertWithMatcher:VisibleInPrimaryToolbar()];
    }
  }
}
}

#pragma mark - TestCase

// Test case for the adaptive toolbar UI.
@interface AdaptiveToolbarTestCase : ChromeTestCase

@end

@implementation AdaptiveToolbarTestCase

// Tests that bookmarks button is selected for the bookmarked pages.
- (void)testBookmarkButton {
  // Setup the bookmarks.
  [ChromeEarlGrey waitForBookmarksToFinishLoading];
  GREYAssert(chrome_test_util::ClearBookmarks(),
             @"Not all bookmarks were removed.");

  // Setup the server.
  self.testServer->RegisterRequestHandler(
      base::BindRepeating(&StandardResponse));
  GREYAssertTrue(self.testServer->Start(), @"Test server failed to start.");

  // Navigate to a page and check the bookmark button is not selected.
  [ChromeEarlGrey loadURL:self.testServer->GetURL(kPageURL)];
  [[EarlGrey selectElementWithMatcher:BookmarkButton()]
      assertWithMatcher:grey_not(grey_selected())];

  // Bookmark the page.
  [[EarlGrey selectElementWithMatcher:BookmarkButton()]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:BookmarkButton()]
      assertWithMatcher:grey_selected()];

  // Navigate to a different page and check the button is not selected.
  [ChromeEarlGrey loadURL:self.testServer->GetURL(kPageURL2)];
  [[EarlGrey selectElementWithMatcher:BookmarkButton()]
      assertWithMatcher:grey_not(grey_selected())];

  // Navigate back to the bookmarked page and check the button.
  [ChromeEarlGrey loadURL:self.testServer->GetURL(kPageURL)];
  [[EarlGrey selectElementWithMatcher:BookmarkButton()]
      assertWithMatcher:grey_selected()];

  // Clean the bookmarks
  GREYAssert(chrome_test_util::ClearBookmarks(),
             @"Not all bookmarks were removed.");
}

// Tests that tapping a button cancels the focus on the omnibox.
- (void)testCancelOmniboxEdit {
  if (IsCompactWidth()) {
    EARL_GREY_TEST_SKIPPED(@"No button to tap in compact width.");
  }

  // Navigate to a page to enable the back button.
  [ChromeEarlGrey loadURL:GURL("chrome://version")];

  // Focus the omnibox.
  [[EarlGrey selectElementWithMatcher:chrome_test_util::Omnibox()]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:chrome_test_util::Omnibox()]
      assertWithMatcher:firstResponder()];

  // Tap the back button and check the omnibox is unfocused.
  [[EarlGrey selectElementWithMatcher:chrome_test_util::BackButton()]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:chrome_test_util::Omnibox()]
      assertWithMatcher:grey_not(firstResponder())];
}

// Verifies that the back/forward buttons are working and are correctly enabled
// during navigations.
- (void)testNavigationButtons {
  // Setup the server.
  self.testServer->RegisterRequestHandler(
      base::BindRepeating(&StandardResponse));
  GREYAssertTrue(self.testServer->Start(), @"Test server failed to start.");

  // Loads two url and check the navigation buttons status.
  [ChromeEarlGrey loadURL:self.testServer->GetURL(kPageURL)];
  [ChromeEarlGrey loadURL:self.testServer->GetURL(kPageURL2)];
  [[EarlGrey selectElementWithMatcher:chrome_test_util::BackButton()]
      assertWithMatcher:grey_interactable()];
  [[EarlGrey selectElementWithMatcher:chrome_test_util::ForwardButton()]
      assertWithMatcher:grey_not(grey_enabled())];

  // Check the navigation to the second page occurred.
  [[EarlGrey selectElementWithMatcher:chrome_test_util::Omnibox()]
      assertWithMatcher:chrome_test_util::OmniboxContainingText(kPageURL2)];

  // Go back.
  [[EarlGrey selectElementWithMatcher:chrome_test_util::BackButton()]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:chrome_test_util::Omnibox()]
      assertWithMatcher:chrome_test_util::OmniboxContainingText(kPageURL)];

  // Check the buttons status.
  [[EarlGrey selectElementWithMatcher:chrome_test_util::BackButton()]
      assertWithMatcher:grey_interactable()];
  [[EarlGrey selectElementWithMatcher:chrome_test_util::ForwardButton()]
      assertWithMatcher:grey_interactable()];

  // Go forward.
  [[EarlGrey selectElementWithMatcher:chrome_test_util::ForwardButton()]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:chrome_test_util::Omnibox()]
      assertWithMatcher:chrome_test_util::OmniboxContainingText(kPageURL2)];

  // Check the buttons status.
  [[EarlGrey selectElementWithMatcher:chrome_test_util::BackButton()]
      assertWithMatcher:grey_interactable()];
  [[EarlGrey selectElementWithMatcher:chrome_test_util::ForwardButton()]
      assertWithMatcher:grey_not(grey_enabled())];

  // Open a page in a new incognito tab to have the focus.
  [[EarlGrey
      selectElementWithMatcher:web::WebViewInWebState(
                                   chrome_test_util::GetCurrentWebState())]
      performAction:chrome_test_util::LongPressElementForContextMenu(
                        kLinkID, true /* menu should appear */)];
  [[EarlGrey selectElementWithMatcher:
                 chrome_test_util::StaticTextWithAccessibilityLabelId(
                     IDS_IOS_CONTENT_CONTEXT_OPENLINKNEWINCOGNITOTAB)]
      performAction:grey_tap()];

  // Check the buttons status.
  [[EarlGrey selectElementWithMatcher:chrome_test_util::BackButton()]
      assertWithMatcher:grey_not(grey_enabled())];
  [[EarlGrey selectElementWithMatcher:chrome_test_util::ForwardButton()]
      assertWithMatcher:grey_not(grey_enabled())];
}

// Tests that tapping the omnibox button focuses the omnibox.
- (void)testOmniboxButton {
  if (!IsSplitToolbarMode()) {
    EARL_GREY_TEST_SKIPPED(@"No omnibox button to tap.");
  }

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(
                                          kToolbarOmniboxButtonIdentifier)]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:chrome_test_util::Omnibox()]
      assertWithMatcher:firstResponder()];
}

// Tests share button is enabled only on pages that can be shared.
- (void)testShareButton {
  // Setup the server.
  self.testServer->RegisterRequestHandler(
      base::BindRepeating(&StandardResponse));
  GREYAssertTrue(self.testServer->Start(), @"Test server failed to start.");
  const GURL pageURL = self.testServer->GetURL(kPageURL);

  // The button is disabled on the NTP.
  [[EarlGrey selectElementWithMatcher:ShareButton()]
      assertWithMatcher:grey_not(grey_enabled())];

  // Navigate to another page and check that the share button is enabled.
  [ChromeEarlGrey loadURL:pageURL];
  [[EarlGrey selectElementWithMatcher:ShareButton()]
      assertWithMatcher:grey_interactable()];
}

// Verifies the existence and state of toolbar UI elements.
- (void)testToolbarUI {
  // Load a page to have the toolbar visible (hidden on NTP).
  [ChromeEarlGrey loadURL:GURL("chrome://version")];

  // Get the original trait collection.
  UIViewController* topViewController =
      top_view_controller::TopPresentedViewController();
  UITraitCollection* originalTraitCollection =
      topViewController.traitCollection;

  // Check the button visibility.
  CheckToolbarButtonVisibility(originalTraitCollection);

  UITraitCollection* secondTraitCollection = nil;
  if (IsIPadIdiom()) {
    // Simulate a multitasking by overriding the trait collections of the view
    // controllers. The rotation doesn't work on iPad.
    UITraitCollection* horizontalCompact = [UITraitCollection
        traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassCompact];
    secondTraitCollection =
        [UITraitCollection traitCollectionWithTraitsFromCollections:@[
          originalTraitCollection, horizontalCompact
        ]];
    for (UIViewController* child in topViewController.childViewControllers) {
      [topViewController setOverrideTraitCollection:secondTraitCollection
                             forChildViewController:child];
    }

  } else {
    // On iPhone rotate to test the the landscape orientation.
    [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft
                             errorOrNil:nil];
    secondTraitCollection = topViewController.traitCollection;
  }

  // Check the visiblity after a size class change.
  CheckToolbarButtonVisibility(secondTraitCollection);

  if (IsIPadIdiom()) {
    // Remove the override.
    for (UIViewController* child in topViewController.childViewControllers) {
      [topViewController setOverrideTraitCollection:originalTraitCollection
                             forChildViewController:child];
    }
  } else {
    // Cancel the rotation.
    [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortrait
                             errorOrNil:nil];
  }
}

@end
