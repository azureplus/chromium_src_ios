// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <EarlGrey/EarlGrey.h>
#import <XCTest/XCTest.h>

#include <memory>

#include "base/test/scoped_feature_list.h"
#include "components/language/core/browser/pref_names.h"
#include "components/translate/core/browser/translate_pref_names.h"
#include "components/translate/core/browser/translate_prefs.h"
#import "ios/chrome/browser/browser_state/chrome_browser_state.h"
#import "ios/chrome/browser/translate/chrome_ios_translate_client.h"
#import "ios/chrome/browser/ui/settings/language/language_settings_ui_constants.h"
#include "ios/chrome/browser/ui/ui_feature_flags.h"
#include "ios/chrome/grit/ios_strings.h"
#import "ios/chrome/test/app/chrome_test_util.h"
#include "ios/chrome/test/earl_grey/accessibility_util.h"
#import "ios/chrome/test/earl_grey/chrome_actions.h"
#import "ios/chrome/test/earl_grey/chrome_earl_grey_ui.h"
#import "ios/chrome/test/earl_grey/chrome_matchers.h"
#import "ios/chrome/test/earl_grey/chrome_test_case.h"
#include "ui/strings/grit/ui_strings.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

using chrome_test_util::ButtonWithAccessibilityLabel;
using chrome_test_util::ButtonWithAccessibilityLabelId;
using chrome_test_util::GetOriginalBrowserState;
using chrome_test_util::NavigationBarDoneButton;
using chrome_test_util::SetBooleanUserPref;
using chrome_test_util::SettingsMenuBackButton;
using chrome_test_util::SettingsSwitchCell;
using chrome_test_util::TurnSettingsSwitchOn;
using chrome_test_util::VerifyAccessibilityForCurrentScreen;
using language::prefs::kAcceptLanguages;

namespace {

// Labels used to identify language entries.
NSString* const kLanguageEntryThreeLabelsTemplate = @"%@, %@, %@";
NSString* const kLanguageEntryTwoLabelsTemplate = @"%@, %@";
NSString* const kEnglishLabel = @"English (United States)";
NSString* const kTurkishLabel = @"Turkish";
NSString* const kTurkishNativeLabel = @"Türkçe";
NSString* const kNeverTranslateLabel = @"Never Translate";
NSString* const kOfferToTranslateLabel = @"Offer to Translate";

// Matcher for the Language Settings's main page table view.
id<GREYMatcher> LanguageSettingsTableView() {
  return grey_allOf(
      grey_accessibilityID(kLanguageSettingsTableViewAccessibilityIdentifier),
      grey_sufficientlyVisible(), nil);
}

// Matcher for the Language Settings's Add Language page table view.
id<GREYMatcher> AddLanguageTableView() {
  return grey_allOf(
      grey_accessibilityID(kAddLanguageTableViewAccessibilityIdentifier),
      grey_sufficientlyVisible(), nil);
}

// Matcher for the Language Settings's Language Details page table view.
id<GREYMatcher> LanguageDetailsTableView() {
  return grey_allOf(
      grey_accessibilityID(kLanguageDetailsTableViewAccessibilityIdentifier),
      grey_sufficientlyVisible(), nil);
}

// Matcher for the Language Settings's general Settings menu entry.
id<GREYMatcher> LanguageSettingsButton() {
  return grey_allOf(
      ButtonWithAccessibilityLabelId(IDS_IOS_LANGUAGE_SETTINGS_TITLE),
      grey_sufficientlyVisible(), nil);
}

// Matcher for the Add Language button in Language Settings's main page.
id<GREYMatcher> AddLanguageButton() {
  return grey_allOf(ButtonWithAccessibilityLabelId(
                        IDS_IOS_LANGUAGE_SETTINGS_ADD_LANGUAGE_BUTTON_TITLE),
                    grey_sufficientlyVisible(), nil);
}

// Matcher for the nav bar's back button to the Language Settings's main page.
id<GREYMatcher> NavigationBarLanguageSettingsButton() {
  return grey_allOf(
      ButtonWithAccessibilityLabelId(IDS_IOS_LANGUAGE_SETTINGS_TITLE),
      grey_kindOfClass([UIButton class]),
      grey_ancestor(grey_kindOfClass([UINavigationBar class])),
      grey_sufficientlyVisible(), nil);
}

// Matcher for the search bar.
id<GREYMatcher> SearchBar() {
  return grey_allOf(
      grey_accessibilityID(kAddLanguageSearchControllerAccessibilityIdentifier),
      grey_sufficientlyVisible(), nil);
}

// Matcher for the search bar's cancel button.
id<GREYMatcher> SearchBarCancelButton() {
  return grey_allOf(ButtonWithAccessibilityLabelId(IDS_APP_CANCEL),
                    grey_kindOfClass([UIButton class]),
                    grey_ancestor(grey_kindOfClass([UISearchBar class])),
                    grey_sufficientlyVisible(), nil);
}

// Matcher for the search bar's scrim.
id<GREYMatcher> SearchBarScrim() {
  return grey_accessibilityID(kAddLanguageSearchScrimAccessibilityIdentifier);
}

// Matcher for a language entry with the given accessibility label. Matches a
// button if |tappable| is true.
id<GREYMatcher> LanguageEntry(NSString* label, BOOL tappable = YES) {
  return grey_allOf(tappable ? ButtonWithAccessibilityLabel(label)
                             : grey_accessibilityLabel(label),
                    grey_sufficientlyVisible(), nil);
}

// Matcher for the "Never Translate" button in the Language Details page.
id<GREYMatcher> NeverTranslateButton() {
  return grey_allOf(ButtonWithAccessibilityLabelId(
                        IDS_IOS_LANGUAGE_SETTINGS_NEVER_TRANSLATE_TITLE),
                    grey_sufficientlyVisible(), nil);
}

// Matcher for the "Offer to Translate" button in the Language Details page.
id<GREYMatcher> OfferToTranslateButton() {
  return grey_allOf(ButtonWithAccessibilityLabelId(
                        IDS_IOS_LANGUAGE_SETTINGS_OFFER_TO_TRANSLATE_TITLE),
                    grey_sufficientlyVisible(), nil);
}

// Matcher for an element with or without the
// UIAccessibilityTraitSelected accessibility trait depending on |selected|.
id<GREYMatcher> ElementIsSelected(BOOL selected) {
  return selected
             ? grey_accessibilityTrait(UIAccessibilityTraitSelected)
             : grey_not(grey_accessibilityTrait(UIAccessibilityTraitSelected));
}

}  // namespace

@interface LanguageSettingsTestCase : ChromeTestCase
@end

@implementation LanguageSettingsTestCase {
  base::test::ScopedFeatureList featureList_;

  std::unique_ptr<translate::TranslatePrefs> translatePrefs_;
}

- (void)setUp {
  [super setUp];

  // Enable the Language Settings UI.
  featureList_.InitAndEnableFeature(kLanguageSettings);

  // Create TranslatePrefs.
  ios::ChromeBrowserState* browserState = GetOriginalBrowserState();
  translatePrefs_ =
      ChromeIOSTranslateClient::CreateTranslatePrefs(browserState->GetPrefs());

  // Make sure Translate is enabled.
  SetBooleanUserPref(browserState, prefs::kOfferTranslateEnabled, YES);

  // Make sure "en-US" is the only accept language.
  std::vector<std::string> languages;
  translatePrefs_->GetLanguageList(&languages);
  for (const auto& language : languages) {
    translatePrefs_->RemoveFromLanguageList(language);
  }
  translatePrefs_->AddToLanguageList("en-US", /*force_blocked=*/false);
}

- (void)tearDown {
  // Go back to the general Settings menu and close it.
  [[EarlGrey selectElementWithMatcher:SettingsMenuBackButton()]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:NavigationBarDoneButton()]
      performAction:grey_tap()];

  [super tearDown];
}

#pragma mark - Test Cases

// Tests that the Language Settings pages are accessible.
- (void)testAccessibility {
  [ChromeEarlGreyUI openSettingsMenu];

  // Test accessibility on the Language Settings's main page.
  [ChromeEarlGreyUI tapSettingsMenuButton:LanguageSettingsButton()];
  [[EarlGrey selectElementWithMatcher:LanguageSettingsTableView()]
      assertWithMatcher:grey_notNil()];
  VerifyAccessibilityForCurrentScreen();

  // Test accessibility on the Add Language page.
  [[EarlGrey selectElementWithMatcher:AddLanguageButton()]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:AddLanguageTableView()]
      assertWithMatcher:grey_notNil()];
  VerifyAccessibilityForCurrentScreen();

  // Navigate back.
  [[EarlGrey selectElementWithMatcher:NavigationBarLanguageSettingsButton()]
      performAction:grey_tap()];

  // Test accessibility on the Language Details page.
  NSString* languageEntryLabel = [NSString
      stringWithFormat:kLanguageEntryThreeLabelsTemplate, kEnglishLabel,
                       kEnglishLabel, kNeverTranslateLabel];
  [[EarlGrey selectElementWithMatcher:LanguageEntry(languageEntryLabel)]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:LanguageDetailsTableView()]
      assertWithMatcher:grey_notNil()];
  VerifyAccessibilityForCurrentScreen();

  // Navigate back.
  [[EarlGrey selectElementWithMatcher:SettingsMenuBackButton()]
      performAction:grey_tap()];
}

// Tests that the Translate Switch enables/disables Translate and the UI gets
// updated accordingly.
- (void)testTransalteSwitch {
  [ChromeEarlGreyUI openSettingsMenu];

  // Go to the Language Settings page.
  [ChromeEarlGreyUI tapSettingsMenuButton:LanguageSettingsButton()];

  // Verify that the Translate switch is on and enabled. Toggle it off.
  [[EarlGrey
      selectElementWithMatcher:SettingsSwitchCell(
                                   kTranslateSwitchAccessibilityIdentifier, YES,
                                   YES)]
      performAction:TurnSettingsSwitchOn(NO)];

  // Verify the prefs are up-to-date.
  GREYAssertFalse(translatePrefs_->IsOfferTranslateEnabled(),
                  @"Translate is expected to be disabled.");

  // Verify that "English (United States)" does not feature a label indicating
  // it is Translate-blocked and it is not tappable.
  NSString* languageEntryLabel =
      [NSString stringWithFormat:kLanguageEntryTwoLabelsTemplate, kEnglishLabel,
                                 kEnglishLabel];
  [[EarlGrey selectElementWithMatcher:LanguageEntry(languageEntryLabel,
                                                    /*tappable=*/NO)]
      assertWithMatcher:grey_notNil()];

  // Verify that the Translate switch is off and enabled. Toggle it on.
  [[EarlGrey
      selectElementWithMatcher:SettingsSwitchCell(
                                   kTranslateSwitchAccessibilityIdentifier, NO,
                                   YES)]
      performAction:TurnSettingsSwitchOn(YES)];

  // Verify the prefs are up-to-date.
  GREYAssertTrue(translatePrefs_->IsOfferTranslateEnabled(),
                 @"Translate is expected to be enabled.");

  // Verify that "English (United States)" features a label indicating it is
  // Translate-blocked.
  languageEntryLabel = [NSString
      stringWithFormat:kLanguageEntryThreeLabelsTemplate, kEnglishLabel,
                       kEnglishLabel, kNeverTranslateLabel];
  [[EarlGrey selectElementWithMatcher:LanguageEntry(languageEntryLabel)]
      assertWithMatcher:grey_notNil()];
}

// Tests that the Add Language page allows filtering languages and adding them
// to the list of accept languages.
- (void)testAddLanguage {
  [ChromeEarlGreyUI openSettingsMenu];

  // Go to the Language Settings page.
  [ChromeEarlGreyUI tapSettingsMenuButton:LanguageSettingsButton()];

  // Go to the Add Language page.
  [[EarlGrey selectElementWithMatcher:AddLanguageButton()]
      performAction:grey_tap()];

  // Verify the "Turkish" language entry is not currently visible.
  NSString* languageEntryLabel =
      [NSString stringWithFormat:kLanguageEntryTwoLabelsTemplate, kTurkishLabel,
                                 kTurkishNativeLabel];
  [[EarlGrey selectElementWithMatcher:LanguageEntry(languageEntryLabel)]
      assertWithMatcher:grey_nil()];

  // Focus the search bar.
  [[EarlGrey selectElementWithMatcher:SearchBar()] performAction:grey_tap()];

  // Verify the scrim is visible when search bar is focused but not typed in.
  [[EarlGrey selectElementWithMatcher:SearchBarScrim()]
      assertWithMatcher:grey_notNil()];

  // Verify the cancel button is visible and unfocuses search bar when tapped.
  [[EarlGrey selectElementWithMatcher:SearchBarCancelButton()]
      performAction:grey_tap()];

  // Verify languages are searchable using their name in the current locale.
  [[EarlGrey selectElementWithMatcher:SearchBar()] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:SearchBar()]
      performAction:grey_replaceText(kTurkishLabel)];

  // Verify that scrim is not visible anymore.
  [[EarlGrey selectElementWithMatcher:SearchBarScrim()]
      assertWithMatcher:grey_nil()];

  // Verify the "Turkish" language entry is visible.
  [[EarlGrey selectElementWithMatcher:LanguageEntry(languageEntryLabel)]
      assertWithMatcher:grey_notNil()];

  // Clear the search.
  [[EarlGrey selectElementWithMatcher:SearchBar()]
      performAction:grey_replaceText(@"")];

  // Verify the scrim is visible again.
  [[EarlGrey selectElementWithMatcher:SearchBarScrim()]
      assertWithMatcher:grey_notNil()];

  // Verify languages are searchable using their name in their native locale.
  [[EarlGrey selectElementWithMatcher:SearchBar()]
      performAction:grey_replaceText(kTurkishNativeLabel)];

  // Verify the "Turkish" language entry is visible and tap it.
  [[EarlGrey selectElementWithMatcher:LanguageEntry(languageEntryLabel)]
      performAction:grey_tap()];

  // Verify that we navigated back to the Language Settings's main page.
  [[EarlGrey selectElementWithMatcher:LanguageSettingsTableView()]
      assertWithMatcher:grey_notNil()];

  // Verify "Turkish" was added to the list of accept languages.
  languageEntryLabel = [NSString
      stringWithFormat:kLanguageEntryThreeLabelsTemplate, kTurkishLabel,
                       kTurkishNativeLabel, kNeverTranslateLabel];
  [[EarlGrey selectElementWithMatcher:LanguageEntry(languageEntryLabel)]
      assertWithMatcher:grey_notNil()];

  // Verify the prefs are up-to-date.
  ios::ChromeBrowserState* browserState = GetOriginalBrowserState();
  GREYAssertEqual("en-US,tr",
                  browserState->GetPrefs()->GetString(kAcceptLanguages),
                  @"Unexpected value for kAcceptLanguages pref");
}

// Tests that the Language Details page allows blocking/unblocking languages.
- (void)testLanguageDetails {
  [ChromeEarlGreyUI openSettingsMenu];

  // Add "Turkish" to the list of accept languages.
  translatePrefs_->AddToLanguageList("tr", /*force_blocked=*/false);
  // Verify the prefs are up-to-date.
  GREYAssertTrue(translatePrefs_->IsBlockedLanguage("tr"),
                 @"Turkish is expected to be Translate-blocked");

  // Go to the Language Settings page.
  [ChromeEarlGreyUI tapSettingsMenuButton:LanguageSettingsButton()];

  // Go to the "Turkish" Language Details page.
  NSString* languageEntryLabel = [NSString
      stringWithFormat:kLanguageEntryThreeLabelsTemplate, kTurkishLabel,
                       kTurkishNativeLabel, kNeverTranslateLabel];
  [[EarlGrey selectElementWithMatcher:LanguageEntry(languageEntryLabel)]
      performAction:grey_tap()];

  // Verify both options are enabled and "Never Translate" is selected.
  [[EarlGrey selectElementWithMatcher:NeverTranslateButton()]
      assertWithMatcher:grey_allOf(grey_enabled(), ElementIsSelected(YES),
                                   nil)];
  [[EarlGrey selectElementWithMatcher:OfferToTranslateButton()]
      assertWithMatcher:grey_allOf(grey_enabled(), ElementIsSelected(NO), nil)];

  // Tap the "Offer to Translate" button.
  [[EarlGrey selectElementWithMatcher:OfferToTranslateButton()]
      performAction:grey_tap()];

  // Verify that we navigated back to the Language Settings's main page.
  [[EarlGrey selectElementWithMatcher:LanguageSettingsTableView()]
      assertWithMatcher:grey_notNil()];

  // Verify that "Turkish" is unblocked.
  languageEntryLabel = [NSString
      stringWithFormat:kLanguageEntryThreeLabelsTemplate, kTurkishLabel,
                       kTurkishNativeLabel, kOfferToTranslateLabel];
  [[EarlGrey selectElementWithMatcher:LanguageEntry(languageEntryLabel)]
      assertWithMatcher:grey_notNil()];

  // Verify the prefs are up-to-date.
  GREYAssertFalse(translatePrefs_->IsBlockedLanguage("tr"),
                  @"Turkish should not be Translate-blocked");

  // Go to the "Turkish" Language Details page.
  [[EarlGrey selectElementWithMatcher:LanguageEntry(languageEntryLabel)]
      performAction:grey_tap()];

  // Verify both options are enabled and "Offer to Translate" is selected.
  [[EarlGrey selectElementWithMatcher:NeverTranslateButton()]
      assertWithMatcher:grey_allOf(grey_enabled(), ElementIsSelected(NO), nil)];
  [[EarlGrey selectElementWithMatcher:OfferToTranslateButton()]
      assertWithMatcher:grey_allOf(grey_enabled(), ElementIsSelected(YES),
                                   nil)];

  // Tap the "Never Translate" button.
  [[EarlGrey selectElementWithMatcher:NeverTranslateButton()]
      performAction:grey_tap()];

  // Verify that we navigated back to the Language Settings's main page.
  [[EarlGrey selectElementWithMatcher:LanguageSettingsTableView()]
      assertWithMatcher:grey_notNil()];

  // Verify "Turkish" is blocked.
  languageEntryLabel = [NSString
      stringWithFormat:kLanguageEntryThreeLabelsTemplate, kTurkishLabel,
                       kTurkishNativeLabel, kNeverTranslateLabel];
  [[EarlGrey selectElementWithMatcher:LanguageEntry(languageEntryLabel)]
      assertWithMatcher:grey_notNil()];

  // Verify the prefs are up-to-date.
  GREYAssertTrue(translatePrefs_->IsBlockedLanguage("tr"),
                 @"Turkish is expected to be Translate-blocked");
}

@end
