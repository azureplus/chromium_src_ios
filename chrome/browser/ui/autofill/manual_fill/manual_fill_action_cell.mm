// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/ui/autofill/manual_fill/manual_fill_action_cell.h"

#include "base/feature_list.h"
#import "ios/chrome/browser/ui/autofill/manual_fill/manual_fill_cell_button.h"
#import "ios/chrome/browser/ui/autofill/manual_fill/manual_fill_cell_utils.h"
#import "ios/chrome/browser/ui/list_model/list_model.h"
#include "ios/chrome/browser/ui/ui_feature_flags.h"
#import "ios/chrome/common/ui/colors/semantic_color_names.h"
#import "ios/chrome/common/ui/util/constraints_ui_util.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

@interface ManualFillActionItem ()

// The action block to be called when the user taps the title.
@property(nonatomic, copy, readonly) void (^action)(void);

// The title for the action.
@property(nonatomic, copy, readonly) NSString* title;

@end

@implementation ManualFillActionItem

- (instancetype)initWithTitle:(NSString*)title action:(void (^)(void))action {
  self = [super initWithType:kItemTypeEnumZero];
  if (self) {
    _title = [title copy];
    _action = [action copy];
    self.cellClass = [ManualFillActionCell class];
  }
  return self;
}

- (void)configureCell:(ManualFillActionCell*)cell
           withStyler:(ChromeTableViewStyler*)styler {
  [super configureCell:cell withStyler:styler];
  cell.accessibilityIdentifier = nil;
  [cell setUpWithTitle:self.title
       accessibilityID:self.accessibilityIdentifier
                action:self.action];
}

@end

#if defined(__IPHONE_13_4)
API_AVAILABLE(ios(13.4))
@interface ManualFillActionCell (Pointer) <UIPointerInteractionDelegate>
@end
#endif  // defined(__IPHONE_13_4)

@interface ManualFillActionCell ()

// The action block to be called when the user taps the title button.
@property(nonatomic, copy) void (^action)(void);

// The title button of this cell.
@property(nonatomic, strong) UIButton* titleButton;

@end

@implementation ManualFillActionCell

#pragma mark - Public

- (void)prepareForReuse {
  [super prepareForReuse];

  self.action = nil;
  [self.titleButton setTitle:nil forState:UIControlStateNormal];
  self.titleButton.accessibilityIdentifier = nil;
}

- (void)setUpWithTitle:(NSString*)title
       accessibilityID:(NSString*)accessibilityID
                action:(void (^)(void))action {
  if (self.contentView.subviews.count == 0) {
    [self createView];
  }

  [self.titleButton setTitle:title forState:UIControlStateNormal];
  self.titleButton.accessibilityIdentifier = accessibilityID;
  self.action = action;
}

#if defined(__IPHONE_13_4)
#pragma mark UIPointerInteractionDelegate

- (UIPointerRegion*)pointerInteraction:(UIPointerInteraction*)interaction
                      regionForRequest:(UIPointerRegionRequest*)request
                         defaultRegion:(UIPointerRegion*)defaultRegion
    API_AVAILABLE(ios(13.4)) {
  return defaultRegion;
}

- (UIPointerStyle*)pointerInteraction:(UIPointerInteraction*)interaction
                       styleForRegion:(UIPointerRegion*)region
    API_AVAILABLE(ios(13.4)) {
  UIPointerHoverEffect* effect = [UIPointerHoverEffect
      effectWithPreview:[[UITargetedPreview alloc] initWithView:self]];
  effect.prefersScaledContent = NO;
  effect.prefersShadow = NO;
  return [UIPointerStyle styleWithEffect:effect shape:nil];
}
#endif  // defined(__IPHONE_13_4)

#pragma mark - Private

- (void)createView {
  self.selectionStyle = UITableViewCellSelectionStyleNone;

  self.titleButton = [ManualFillCellButton buttonWithType:UIButtonTypeCustom];
  [self.titleButton addTarget:self
                       action:@selector(userDidTapTitleButton:)
             forControlEvents:UIControlEventTouchUpInside];

  [self.contentView addSubview:self.titleButton];

  NSMutableArray<NSLayoutConstraint*>* constraints =
      [[NSMutableArray alloc] initWithArray:@[
        [self.contentView.topAnchor
            constraintEqualToAnchor:self.titleButton.topAnchor],
        [self.contentView.bottomAnchor
            constraintEqualToAnchor:self.titleButton.bottomAnchor],
      ]];
  AppendHorizontalConstraintsForViews(constraints, @[ self.titleButton ],
                                      self.contentView);
  [NSLayoutConstraint activateConstraints:constraints];
#if defined(__IPHONE_13_4)
  if (@available(iOS 13.4, *)) {
    if (base::FeatureList::IsEnabled(kPointerSupport)) {
      [self
          addInteraction:[[UIPointerInteraction alloc] initWithDelegate:self]];
    }
  }
#endif  // defined(__IPHONE_13_4)
}

- (void)userDidTapTitleButton:(UIButton*)sender {
  if (self.action) {
    self.action();
  }
}

@end
