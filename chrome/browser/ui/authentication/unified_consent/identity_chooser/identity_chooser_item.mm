// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/ui/authentication/unified_consent/identity_chooser/identity_chooser_item.h"

#import "ios/chrome/browser/ui/authentication/unified_consent/identity_chooser/identity_chooser_cell.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

@implementation IdentityChooserItem

@synthesize gaiaID = _gaiaID;
@synthesize name = _name;
@synthesize email = _email;
@synthesize avatar = _avatar;
@synthesize selected = _selected;

- (instancetype)initWithType:(NSInteger)type {
  self = [super initWithType:type];
  if (self) {
    self.cellClass = [IdentityChooserCell class];
  }
  return self;
}

- (void)configureCell:(IdentityChooserCell*)cell
           withStyler:(ChromeTableViewStyler*)styler {
  [super configureCell:cell withStyler:styler];
  NSString* title = self.name;
  NSString* subtitle = self.email;
  if (!title.length) {
    title = subtitle;
    subtitle = nil;
  }
  [cell configureCellWithTitle:title
                      subtitle:subtitle
                         image:self.avatar
                       checked:self.selected];
}

@end
