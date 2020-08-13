// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/ui/menu/menu_histograms.h"

#import "base/metrics/histogram_functions.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

namespace {
// Histogram for tracking menu scenario started.
const char kMenuEntryPointsHistogram[] = "Mobile.ContextMenu.EntryPoints";

// Histograms for tracking actions performed on given menus.
const char kHistoryEntryActionsHistogram[] =
    "Mobile.ContextMenu.HistoryEntry.Actions";
const char kBookmarkEntryActionsHistogram[] =
    "Mobile.ContextMenu.BookmarkEntry.Actions";
const char kReadingListEntryActionsHistogram[] =
    "Mobile.ContextMenu.ReadingListEntry.Actions";
const char kRecentTabsEntryActionsHistogram[] =
    "Mobile.ContextMenu.RecentTabsEntry.Actions";
const char kRecentTabsHeaderActionsHistogram[] =
    "Mobile.ContextMenu.RecentTabsHeader.Actions";
const char kContentSuggestionsEntryActionsHistogram[] =
    "Mobile.ContextMenu.ContentSuggestionsEntry.Actions";
const char kBookmarkFolderActionsHistogram[] =
    "Mobile.ContextMenu.BookmarkFolder.Actions";
}  // namespace

void RecordMenuShown(MenuScenario scenario) {
  base::UmaHistogramEnumeration(kMenuEntryPointsHistogram, scenario);
}

const char* GetActionsHistogramName(MenuScenario scenario) {
  switch (scenario) {
    case MenuScenario::kHistoryEntry:
      return kHistoryEntryActionsHistogram;
    case MenuScenario::kBookmarkEntry:
      return kBookmarkEntryActionsHistogram;
    case MenuScenario::kReadingListEntry:
      return kReadingListEntryActionsHistogram;
    case MenuScenario::kRecentTabsEntry:
      return kRecentTabsEntryActionsHistogram;
    case MenuScenario::kRecentTabsHeader:
      return kRecentTabsHeaderActionsHistogram;
    case MenuScenario::kContentSuggestionsEntry:
      return kContentSuggestionsEntryActionsHistogram;
    case MenuScenario::kBookmarkFolder:
      return kBookmarkFolderActionsHistogram;
  }
}
