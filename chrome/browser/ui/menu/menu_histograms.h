// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_UI_MENU_MENU_HISTOGRAMS_H_
#define IOS_CHROME_BROWSER_UI_MENU_MENU_HISTOGRAMS_H_

// Enum representing the existing set of menu scenarios. Current values should
// not be renumbered. Please keep in sync with "IOSMenuScenario" in
// src/tools/metrics/histograms/enums.xml.
enum class MenuScenario {
  kHistoryEntry = 0,
  kBookmarkEntry = 1,
  kReadingListEntry = 2,
  kRecentTabsEntry = 3,
  kContentSuggestionsEntry = 4,
  kMaxValue = kContentSuggestionsEntry
};

// Records a menu shown histogram metric for the |scenario|.
void RecordMenuShown(MenuScenario scenario);

// Retrieves a histogram name for the given menu |scenario|'s actions.
const char* GetActionsHistogramName(MenuScenario scenario);

#endif  // IOS_CHROME_BROWSER_UI_MENU_MENU_HISTOGRAMS_H_