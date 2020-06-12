// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/ui/page_info/page_info_view_controller.h"

#include "base/mac/foundation_util.h"
#include "components/content_settings/core/common/features.h"
#include "ios/chrome/browser/chrome_url_constants.h"
#include "ios/chrome/browser/ui/commands/browser_commands.h"
#import "ios/chrome/browser/ui/page_info/features.h"
#import "ios/chrome/browser/ui/page_info/page_info_cookies_commands.h"
#import "ios/chrome/browser/ui/settings/cells/settings_switch_cell.h"
#import "ios/chrome/browser/ui/settings/cells/settings_switch_item.h"
#import "ios/chrome/browser/ui/table_view/cells/table_view_detail_icon_item.h"
#import "ios/chrome/browser/ui/table_view/cells/table_view_multi_detail_text_item.h"
#import "ios/chrome/browser/ui/table_view/cells/table_view_text_header_footer_item.h"
#import "ios/chrome/browser/ui/table_view/cells/table_view_text_item.h"
#import "ios/chrome/browser/ui/table_view/cells/table_view_text_link_item.h"
#include "ios/chrome/browser/ui/ui_feature_flags.h"
#import "ios/chrome/common/ui/colors/semantic_color_names.h"
#include "ios/chrome/grit/ios_strings.h"
#include "ui/base/l10n/l10n_util.h"
#include "url/gurl.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

namespace {

typedef NS_ENUM(NSInteger, SectionIdentifier) {
  SectionIdentifierSecurityContent = kSectionIdentifierEnumZero,
  SectionIdentifierCookiesContent
};

typedef NS_ENUM(NSInteger, ItemType) {
  ItemTypeSecurityHeader = kItemTypeEnumZero,
  ItemTypeSecurityDescription,
  ItemTypeCookiesHeader,
  ITemTypeCookiesFooter,
};

// The vertical padding between the navigation bar and the Security header.
float kPaddingSecurityHeader = 28.0f;
// The vertical padding between the Security section and the Cookies section.
float kPaddingCookiesHeader = 0.0f;

}  // namespace

@interface PageInfoViewController () <TableViewTextLinkCellDelegate>

@property(nonatomic, strong)
    PageInfoSiteSecurityDescription* pageInfoSecurityDescription;
@property(nonatomic, strong)
    PageInfoCookiesDescription* pageInfoCookiesDescription;

@end

@implementation PageInfoViewController

#pragma mark - UIViewController

- (instancetype)initWithSiteSecurityDescription:
                    (PageInfoSiteSecurityDescription*)siteSecurityDescription
                             cookiesDescription:(PageInfoCookiesDescription*)
                                                    cookiesDescription {
  self = [super initWithStyle:UITableViewStylePlain];
  if (self) {
    _pageInfoSecurityDescription = siteSecurityDescription;
    _pageInfoCookiesDescription = cookiesDescription;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.title = l10n_util::GetNSString(IDS_IOS_PAGE_INFO_SITE_INFORMATION);
  self.navigationItem.prompt = self.pageInfoSecurityDescription.siteURL;
  self.navigationController.navigationBar.prefersLargeTitles = NO;

  UIBarButtonItem* dismissButton = [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                           target:self.handler
                           action:@selector(hidePageInfo)];
  self.navigationItem.rightBarButtonItem = dismissButton;
  self.tableView.allowsSelection = NO;

  if (self.pageInfoSecurityDescription.isEmpty) {
    [self addEmptyTableViewWithMessage:self.pageInfoSecurityDescription.message
                                 image:nil];
    self.tableView.alwaysBounceVertical = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    return;
  }

  [self loadModel];
}

#pragma mark - ChromeTableViewController

- (void)loadModel {
  [super loadModel];

  [self.tableViewModel
      addSectionWithIdentifier:SectionIdentifierSecurityContent];
  [self.tableViewModel
      addSectionWithIdentifier:SectionIdentifierCookiesContent];

  TableViewDetailIconItem* securityHeader =
      [[TableViewDetailIconItem alloc] initWithType:ItemTypeSecurityHeader];
  securityHeader.text = l10n_util::GetNSString(IDS_IOS_PAGE_INFO_SITE_SECURITY);
  securityHeader.detailText = self.pageInfoSecurityDescription.status;
  securityHeader.iconImageName = self.pageInfoSecurityDescription.iconImageName;
  [self.tableViewModel addItem:securityHeader
       toSectionWithIdentifier:SectionIdentifierSecurityContent];

  TableViewTextLinkItem* securityDescription =
      [[TableViewTextLinkItem alloc] initWithType:ItemTypeSecurityDescription];
  securityDescription.text = self.pageInfoSecurityDescription.message;
  securityDescription.linkURL = GURL(kPageInfoHelpCenterURL);
  [self.tableViewModel addItem:securityDescription
       toSectionWithIdentifier:SectionIdentifierSecurityContent];

  if (base::FeatureList::IsEnabled(content_settings::kImprovedCookieControls))
    [self loadCookiesModel];
}

#pragma mark - Private

// Adds Items to the tableView related to Cookies Settings.
- (void)loadCookiesModel {
  TableViewDetailIconItem* cookiesHeader =
      [[TableViewDetailIconItem alloc] initWithType:ItemTypeCookiesHeader];
  cookiesHeader.text = l10n_util::GetNSString(IDS_IOS_PAGE_INFO_COOKIES_HEADER);
  cookiesHeader.detailText = self.pageInfoCookiesDescription.headerDescription;
  cookiesHeader.iconImageName = @"cookies_icon";
  [self.tableViewModel addItem:cookiesHeader
       toSectionWithIdentifier:SectionIdentifierCookiesContent];

  TableViewTextLinkItem* cookiesFooter =
      [[TableViewTextLinkItem alloc] initWithType:ITemTypeCookiesFooter];
  cookiesFooter.text = self.pageInfoCookiesDescription.footerDescription;
  cookiesFooter.linkURL = GURL(kChromeUICookiesSettingsURL);
  [self.tableViewModel addItem:cookiesFooter
       toSectionWithIdentifier:SectionIdentifierCookiesContent];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView*)tableView
    heightForHeaderInSection:(NSInteger)section {
  if ([self.tableViewModel sectionIdentifierForSection:section] ==
      SectionIdentifierSecurityContent)
    return kPaddingSecurityHeader;
  return kPaddingCookiesHeader;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  UITableViewCell* cellToReturn = [super tableView:tableView
                             cellForRowAtIndexPath:indexPath];
  TableViewItem* item = [self.tableViewModel itemAtIndexPath:indexPath];

  if (item.type == ItemTypeSecurityDescription ||
      item.type == ITemTypeCookiesFooter) {
    TableViewTextLinkCell* tableViewTextLinkCell =
        base::mac::ObjCCastStrict<TableViewTextLinkCell>(cellToReturn);
    tableViewTextLinkCell.delegate = self;
  }

  return cellToReturn;
}

#pragma mark - TableViewTextLinkCellDelegate

- (void)tableViewTextLinkCell:(TableViewTextLinkCell*)cell
            didRequestOpenURL:(const GURL&)URL {
  if (URL == GURL(kPageInfoHelpCenterURL))
    [self.handler showSecurityHelpPage];
  if (URL == GURL(kChromeUICookiesSettingsURL))
    [self.handler showCookiesSettingsPage];
}

#pragma mark - PageInfoCookiesConsumer

- (void)cookiesOptionChangedToDescription:
    (PageInfoCookiesDescription*)description {
  // Update the Cookies Header.
  NSIndexPath* headerPath = [self.tableViewModel
      indexPathForItemType:ItemTypeCookiesHeader
         sectionIdentifier:SectionIdentifierCookiesContent];
  TableViewDetailIconItem* cookiesHeader =
      base::mac::ObjCCastStrict<TableViewDetailIconItem>(
          [self.tableViewModel itemAtIndexPath:headerPath]);
  cookiesHeader.detailText = description.headerDescription;

  // Update the Cookies footer.
  NSIndexPath* footerPath = [self.tableViewModel
      indexPathForItemType:ITemTypeCookiesFooter
         sectionIdentifier:SectionIdentifierCookiesContent];
  TableViewTextLinkItem* cookiesFooter =
      base::mac::ObjCCastStrict<TableViewTextLinkItem>(
          [self.tableViewModel itemAtIndexPath:footerPath]);
  cookiesFooter.text = description.footerDescription;

  [self reconfigureCellsForItems:@[ cookiesHeader, cookiesFooter ]];
}

@end
