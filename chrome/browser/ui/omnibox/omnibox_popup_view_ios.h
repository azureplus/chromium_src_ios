// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_UI_OMNIBOX_OMNIBOX_POPUP_VIEW_IOS_H_
#define IOS_CHROME_BROWSER_UI_OMNIBOX_OMNIBOX_POPUP_VIEW_IOS_H_

#import <UIKit/UIKit.h>

#include <memory>

#include "base/strings/string16.h"
#include "components/omnibox/browser/omnibox_popup_view.h"
#import "ios/chrome/browser/ui/omnibox/omnibox_popup_mediator.h"
#include "ios/chrome/browser/ui/omnibox/omnibox_popup_provider.h"
#import "ios/chrome/browser/ui/omnibox/omnibox_popup_view_controller.h"

class OmniboxEditModel;
@class OmniboxPopupMediator;
class OmniboxPopupModel;
class OmniboxPopupViewSuggestionsDelegate;
struct AutocompleteMatch;

// iOS implementation of AutocompletePopupView.
class OmniboxPopupViewIOS : public OmniboxPopupView,
                            public OmniboxPopupMediatorDelegate,
                            public OmniboxPopupProvider {
 public:
  OmniboxPopupViewIOS(OmniboxEditModel* edit_model,
                      OmniboxPopupViewSuggestionsDelegate* delegate);
  ~OmniboxPopupViewIOS() override;

  // Popup model used for this.
  OmniboxPopupModel* model() const;

  // AutocompletePopupView implementation.
  bool IsOpen() const override;
  void InvalidateLine(size_t line) override {}
  void OnLineSelected(size_t line) override {}
  void UpdatePopupAppearance() override;
  void OnMatchIconUpdated(size_t match_index) override {}
  void PaintUpdatesNow() override {}
  void OnDragCanceled() override {}

  void UpdateEditViewIcon();

  // OmniboxPopupProvider implemetation.
  void SetTextAlignment(NSTextAlignment alignment) override;
  bool IsPopupOpen() override;

  // OmniboxPopupViewControllerDelegate implementation.
  bool IsStarredMatch(const AutocompleteMatch& match) const override;
  void OnMatchSelected(const AutocompleteMatch& match, size_t row) override;
  void OnMatchSelectedForAppending(const AutocompleteMatch& match) override;
  void OnMatchSelectedForDeletion(const AutocompleteMatch& match) override;
  void OnScroll() override;

  void SetMediator(OmniboxPopupMediator* mediator) { mediator_ = mediator; }

 private:
  std::unique_ptr<OmniboxPopupModel> model_;
  OmniboxPopupViewSuggestionsDelegate* delegate_;  // weak
  OmniboxPopupMediator* mediator_;
};

#endif  // IOS_CHROME_BROWSER_UI_OMNIBOX_OMNIBOX_POPUP_VIEW_IOS_H_
