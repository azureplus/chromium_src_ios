// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/ui/history/history_entry_inserter.h"

#include "base/mac/foundation_util.h"
#include "base/strings/sys_string_conversions.h"
#include "base/time/time.h"
#include "ios/chrome/browser/experimental_flags.h"
#import "ios/chrome/browser/ui/collection_view/cells/collection_view_text_item.h"
#import "ios/chrome/browser/ui/history/history_entry_item_interface.h"
#include "ios/chrome/browser/ui/history/history_util.h"
#import "ios/chrome/browser/ui/history/legacy_history_entry_item.h"
#import "ios/chrome/browser/ui/list_model/list_model.h"
#import "ios/chrome/browser/ui/table_view/cells/table_view_text_header_footer_item.h"
#include "url/gurl.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

@interface HistoryEntryInserter () {
  // ListModel in which to insert history entries.
  ListModel* _listModel;
  // The index of the first section to contain history entries.
  NSInteger _firstSectionIndex;
  // Number of assigned section identifiers.
  NSInteger _sectionIdentifierCount;
  // Sorted set of dates that have history entries.
  NSMutableOrderedSet* _dates;
  // Mapping from dates to section identifiers.
  NSMutableDictionary* _sectionIdentifiers;
}

@end

@implementation HistoryEntryInserter
@synthesize delegate = _delegate;

- (instancetype)initWithModel:(ListModel*)listModel {
  if ((self = [super init])) {
    _listModel = listModel;
    _firstSectionIndex = [listModel numberOfSections];
    _dates = [[NSMutableOrderedSet alloc] init];
    _sectionIdentifiers = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)insertHistoryEntryItem:(ListItem<HistoryEntryItemInterface>*)item {
  NSInteger sectionIdentifier =
      [self sectionIdentifierForTimestamp:item.timestamp];

  NSComparator objectComparator = ^(id obj1, id obj2) {
    LegacyHistoryEntryItem* firstObject =
        base::mac::ObjCCastStrict<LegacyHistoryEntryItem>(obj1);
    LegacyHistoryEntryItem* secondObject =
        base::mac::ObjCCastStrict<LegacyHistoryEntryItem>(obj2);
    if ([firstObject isEqualToHistoryEntryItem:secondObject])
      return NSOrderedSame;

    // History entries are ordered from most to least recent.
    if (firstObject.timestamp > secondObject.timestamp)
      return NSOrderedAscending;
    if (firstObject.timestamp < secondObject.timestamp)
      return NSOrderedDescending;
    return firstObject.URL < secondObject.URL ? NSOrderedAscending
                                              : NSOrderedDescending;
  };

  NSArray* items = [_listModel itemsInSectionWithIdentifier:sectionIdentifier];
  NSRange range = NSMakeRange(0, [items count]);
  // If the object is not already in the section, insert it.
  if ([items indexOfObject:item
             inSortedRange:range
                   options:NSBinarySearchingFirstEqual
           usingComparator:objectComparator] == NSNotFound) {
    // Insert the object at the appropriate index to keep the section sorted.
    NSUInteger index = [items indexOfObject:item
                              inSortedRange:range
                                    options:NSBinarySearchingInsertionIndex
                            usingComparator:objectComparator];
    [_listModel insertItem:item
        inSectionWithIdentifier:sectionIdentifier
                        atIndex:index];
    NSIndexPath* indexPath = [NSIndexPath
        indexPathForItem:index
               inSection:[_listModel
                             sectionForSectionIdentifier:sectionIdentifier]];
    [self.delegate historyEntryInserter:self
               didInsertItemAtIndexPath:indexPath];
  }
}

- (NSUInteger)sectionIdentifierForTimestamp:(base::Time)timestamp {
  base::TimeDelta timeDelta =
      timestamp.LocalMidnight() - base::Time::UnixEpoch();
  NSDate* date = [NSDate dateWithTimeIntervalSince1970:timeDelta.InSeconds()];

  NSInteger sectionIdentifier =
      [[_sectionIdentifiers objectForKey:date] integerValue];
  // If there is a section identifier for the date, return it.
  if (sectionIdentifier) {
    return sectionIdentifier;
  }

  // Get the next section identifier, and add a section for date.
  sectionIdentifier =
      kSectionIdentifierEnumZero + _firstSectionIndex + _sectionIdentifierCount;
  ++_sectionIdentifierCount;
  [_sectionIdentifiers setObject:@(sectionIdentifier) forKey:date];

  NSComparator comparator = ^(id obj1, id obj2) {
    // Dates are ordered from most to least recent.
    return [obj2 compare:obj1];
  };
  NSUInteger index = [_dates indexOfObject:date
                             inSortedRange:NSMakeRange(0, [_dates count])
                                   options:NSBinarySearchingInsertionIndex
                           usingComparator:comparator];
  [_dates insertObject:date atIndex:index];
  NSInteger insertionIndex = _firstSectionIndex + index;
  if (experimental_flags::IsCollectionsUIRebootEnabled()) {
    TableViewTextHeaderFooterItem* header =
        [[TableViewTextHeaderFooterItem alloc] initWithType:kItemTypeEnumZero];
    header.text =
        base::SysUTF16ToNSString(history::GetRelativeDateLocalized(timestamp));
    [_listModel setHeader:header forSectionWithIdentifier:sectionIdentifier];

  } else {
    CollectionViewTextItem* header =
        [[CollectionViewTextItem alloc] initWithType:kItemTypeEnumZero];
    header.text =
        base::SysUTF16ToNSString(history::GetRelativeDateLocalized(timestamp));
    [_listModel setHeader:header forSectionWithIdentifier:sectionIdentifier];
  }
  [_listModel insertSectionWithIdentifier:sectionIdentifier
                                  atIndex:insertionIndex];
  [self.delegate historyEntryInserter:self
              didInsertSectionAtIndex:insertionIndex];
  return sectionIdentifier;
}

- (void)removeSection:(NSInteger)sectionIndex {
  NSUInteger sectionIdentifier =
      [_listModel sectionIdentifierForSection:sectionIndex];

  // Sections should not be removed unless there are no items in that section.
  DCHECK(![[_listModel itemsInSectionWithIdentifier:sectionIdentifier] count]);
  [_listModel removeSectionWithIdentifier:sectionIdentifier];

  NSEnumerator* dateEnumerator = [_sectionIdentifiers keyEnumerator];
  NSDate* date = nil;
  while ((date = [dateEnumerator nextObject])) {
    if ([[_sectionIdentifiers objectForKey:date] unsignedIntegerValue] ==
        sectionIdentifier) {
      [_sectionIdentifiers removeObjectForKey:date];
      [_dates removeObject:date];
      break;
    }
  }
  [self.delegate historyEntryInserter:self
              didRemoveSectionAtIndex:sectionIndex];
}

@end
