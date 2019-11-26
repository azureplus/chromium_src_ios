// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/ui/infobars/modals/infobar_translate_language_selection_table_view_controller.h"

#include "base/strings/sys_string_conversions.h"
#include "components/translate/core/browser/translate_infobar_delegate.h"
#import "ios/chrome/browser/ui/infobars/modals/infobar_translate_language_selection_delegate.h"
#import "ios/chrome/browser/ui/table_view/cells/table_view_cells_constants.h"
#import "ios/chrome/browser/ui/table_view/cells/table_view_text_item.h"
#import "ios/chrome/browser/ui/table_view/chrome_table_view_styler.h"
#import "ios/chrome/common/colors/semantic_color_names.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

typedef NS_ENUM(NSInteger, SectionIdentifier) {
  SectionIdentifierContent = kSectionIdentifierEnumZero,
};

@interface InfobarTranslateLanguageSelectionTableViewController ()

// Stores the items received from
// setTranslateLanguageItems:forChangingSourceLanguage: to populate the
// TableViewModel in loadModel.
@property(nonatomic, strong) NSArray<TableViewTextItem*>* modelItems;

// YES if this ViewController is displaying language options to change change
// the source language. NO if it is displaying language options to change the
// target language.
@property(nonatomic, assign) BOOL selectingSourceLanguage;

// The InfobarTranslateLanguageSelectionDelegate for this ViewController.
@property(nonatomic, strong) id<InfobarTranslateLanguageSelectionDelegate>
    langageSelectionDelegate;

@end

@implementation InfobarTranslateLanguageSelectionTableViewController

- (instancetype)initWithDelegate:(id<InfobarTranslateLanguageSelectionDelegate>)
                                     langageSelectionDelegate
         selectingSourceLanguage:(BOOL)sourceLanguage {
  self = [super initWithTableViewStyle:UITableViewStylePlain
                           appBarStyle:ChromeTableViewControllerStyleNoAppBar];
  if (self) {
    _langageSelectionDelegate = langageSelectionDelegate;
    _selectingSourceLanguage = sourceLanguage;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor colorNamed:kBackgroundColor];
  self.styler.cellBackgroundColor = [UIColor colorNamed:kBackgroundColor];
  self.tableView.sectionHeaderHeight = 0;
  [self.tableView
      setSeparatorInset:UIEdgeInsetsMake(0, kTableViewHorizontalSpacing, 0, 0)];

  [self loadModel];
}

- (void)loadModel {
  [super loadModel];
  TableViewModel* model = self.tableViewModel;
  [model addSectionWithIdentifier:SectionIdentifierContent];
  for (TableViewTextItem* item in self.modelItems) {
    [self.tableViewModel addItem:item
         toSectionWithIdentifier:SectionIdentifierContent];
  }
}

#pragma mark - InfobarTranslateLanguageSelectionConsumer

- (void)setTranslateLanguageItems:(NSArray<TableViewTextItem*>*)items {
  // If this is called after viewDidLoad/loadModel, then a [self.tableView
  // reloadData] call will be needed or else the items displayed won't be
  // updated.
  self.modelItems = items;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView*)tableView
    didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  // All items should be a TableViewTextItem and of just one type
  // kItemTypeEnumZero. They are populated in the mediator with this assumption.
  TableViewTextItem* item = static_cast<TableViewTextItem*>(
      [self.tableViewModel itemAtIndexPath:indexPath]);
  DCHECK(item.type == kItemTypeEnumZero);
  if (self.selectingSourceLanguage) {
    [self.langageSelectionDelegate didSelectSourceLanguageIndex:indexPath.row
                                                       withName:item.text];
  } else {
    [self.langageSelectionDelegate didSelectTargetLanguageIndex:indexPath.row
                                                       withName:item.text];
  }
}

@end