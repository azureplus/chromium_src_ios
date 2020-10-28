// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/ui/settings/cells/settings_image_detail_text_item.h"

#import "ios/chrome/browser/ui/settings/cells/settings_image_detail_text_cell.h"
#import "ios/chrome/browser/ui/table_view/chrome_table_view_styler.h"
#import "ios/chrome/common/ui/colors/UIColor+cr_semantic_colors.h"
#include "testing/gtest/include/gtest/gtest.h"
#import "testing/gtest_mac.h"
#include "testing/platform_test.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

using SettingsImageDetailTextItemTest = PlatformTest;

// Tests that the text, detail text and image are honoured after a call to
// |configureCell:|.
TEST_F(SettingsImageDetailTextItemTest, ConfigureCell) {
  SettingsImageDetailTextItem* item =
      [[SettingsImageDetailTextItem alloc] initWithType:0];
  NSString* text = @"Test Text";
  NSString* detailText = @"Test Detail Text";
  UIImage* image = [[UIImage alloc] init];
  item.image = image;
  item.text = text;
  item.detailText = detailText;

  id cell = [[[item cellClass] alloc] init];
  ASSERT_TRUE([cell isMemberOfClass:[SettingsImageDetailTextCell class]]);

  SettingsImageDetailTextCell* imageDetailCell =
      static_cast<SettingsImageDetailTextCell*>(cell);

  EXPECT_FALSE(imageDetailCell.textLabel.text);
  EXPECT_FALSE(imageDetailCell.detailTextLabel.text);

  [item configureCell:cell withStyler:[[ChromeTableViewStyler alloc] init]];
  EXPECT_NSEQ(text, imageDetailCell.textLabel.text);
  EXPECT_NSEQ(detailText, imageDetailCell.detailTextLabel.text);
  EXPECT_NSEQ(UIColor.cr_secondaryLabelColor,
              imageDetailCell.detailTextLabel.textColor);
  EXPECT_NSEQ(image, imageDetailCell.image);
}

// Tests that the detail text color is updated when detailTextColor is not
// nil.
TEST_F(SettingsImageDetailTextItemTest, setDetailTextColor) {
  SettingsImageDetailTextItem* item =
      [[SettingsImageDetailTextItem alloc] initWithType:0];
  NSString* text = @"Test Text";
  NSString* detailText = @"Test Detail Text";
  item.text = text;
  item.detailText = detailText;
  item.detailTextColor = UIColor.blueColor;
  item.image = [[UIImage alloc] init];

  id cell = [[[item cellClass] alloc] init];
  ASSERT_TRUE([cell isMemberOfClass:[SettingsImageDetailTextCell class]]);

  [item configureCell:cell withStyler:[[ChromeTableViewStyler alloc] init]];

  SettingsImageDetailTextCell* imageDetailCell =
      static_cast<SettingsImageDetailTextCell*>(cell);

  EXPECT_NSEQ(UIColor.blueColor, imageDetailCell.detailTextLabel.textColor);
}