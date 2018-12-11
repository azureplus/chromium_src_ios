// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_UI_BROWSER_VIEW_CONTROLLER_H_
#define IOS_CHROME_BROWSER_UI_BROWSER_VIEW_CONTROLLER_H_

#import <UIKit/UIKit.h>

#import "base/ios/block_types.h"
#import "ios/chrome/browser/ui/page_info/requirements/page_info_presentation.h"
#import "ios/chrome/browser/ui/settings/sync_utils/sync_presenter.h"
#import "ios/chrome/browser/ui/toolbar/toolbar_coordinator_delegate.h"
#import "ios/chrome/browser/ui/url_loader.h"
#import "ios/public/provider/chrome/browser/voice/logo_animation_controller.h"

@protocol ApplicationCommands;
@protocol BrowserCommands;
@class BrowserViewControllerDependencyFactory;
@class CommandDispatcher;
class GURL;
@protocol OmniboxFocuser;
@protocol PopupMenuCommands;
@protocol FakeboxFocuser;
@protocol SnackbarCommands;
@class TabModel;
@protocol TabStripFoldAnimation;
@protocol ToolbarCommands;

namespace ios {
class ChromeBrowserState;
}

// The top-level view controller for the browser UI. Manages other controllers
// which implement the interface.
@interface BrowserViewController
    : UIViewController <LogoAnimationControllerOwnerOwner,
                        PageInfoPresentation,
                        SyncPresenter,
                        ToolbarCoordinatorDelegate,
                        UrlLoader>

// Initializes a new BVC from its nib. |model| must not be nil. The
// webUsageSuspended property for this BVC will be based on |model|, and future
// changes to |model|'s suspension state should be made through this BVC
// instead of directly on the model.
- (instancetype)
          initWithTabModel:(TabModel*)model
              browserState:(ios::ChromeBrowserState*)browserState
         dependencyFactory:(BrowserViewControllerDependencyFactory*)factory
applicationCommandEndpoint:(id<ApplicationCommands>)applicationCommandEndpoint
         commandDispatcher:(CommandDispatcher*)commandDispatcher
    NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithNibName:(NSString*)nibNameOrNil
                         bundle:(NSBundle*)nibBundleOrNil NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder*)aDecoder NS_UNAVAILABLE;

@property(nonatomic, readonly) id<ApplicationCommands,
                                  BrowserCommands,
                                  OmniboxFocuser,
                                  PopupMenuCommands,
                                  FakeboxFocuser,
                                  SnackbarCommands,
                                  ToolbarCommands,
                                  UrlLoader>
    dispatcher;

// The top-level browser container view.
@property(nonatomic, strong, readonly) UIView* contentArea;

// Invisible button used to dismiss the keyboard.
@property(nonatomic, strong) UIButton* typingShield;

// Returns whether or not text to speech is playing.
@property(nonatomic, assign, readonly, getter=isPlayingTTS) BOOL playingTTS;

// Returns the TabModel passed to the initializer.
@property(nonatomic, weak, readonly) TabModel* tabModel;

// Returns the ios::ChromeBrowserState passed to the initializer.
@property(nonatomic, assign, readonly) ios::ChromeBrowserState* browserState;

// Whether the receiver is currently the primary BVC.
- (void)setPrimary:(BOOL)primary;

// Called when the typing shield is tapped.
- (void)shieldWasTapped:(id)sender;

// Called when the user explicitly opens the tab switcher.
- (void)userEnteredTabSwitcher;

// Presents either in-product help bubbles if the the user is in a valid state
// to see one of them. At most one bubble will be shown. If the feature
// engagement tracker determines it is not valid to see one of the bubbles, that
// bubble will not be shown.
- (void)presentBubblesIfEligible;

// Opens a new tab as if originating from |originPoint| and |focusOmnibox|.
- (void)openNewTabFromOriginPoint:(CGPoint)originPoint
                     focusOmnibox:(BOOL)focusOmnibox;

// Adds |tabAddedCompletion| to the completion block (if any) that will be run
// the next time a tab is added to the TabModel this object was initialized
// with.
- (void)appendTabAddedCompletion:(ProceduralBlock)tabAddedCompletion;

// Informs the BVC that a new foreground tab is about to be opened. This is
// intended to be called before setWebUsageSuspended:NO in cases where a new tab
// is about to appear in order to allow the BVC to avoid doing unnecessary work
// related to showing the previously selected tab.
- (void)expectNewForegroundTab;

// Shows the voice search UI.
- (void)startVoiceSearch;

// Returns a tab strip placeholder view created from the current state of the
// tab strip. It is used to animate the transition from the browser view
// controller to the tab switcher.
- (UIView<TabStripFoldAnimation>*)tabStripPlaceholderView;

// Shows the activity overlay to inform users and prevent users from
// interacting. This method should only be used for clear browsing data.
// TODO(crbug.com/913338): Remove after clear browsing data coordinator is
// created.
- (void)showActivityOverlay;

// Dismisses the activity overlay if it was started.
- (void)dismissActivityOverlay;

// Reset all New Tab Page coordinators to force them to reload their content.
// TODO(crbug.com/906199): NewTabPageTabHelper should use an observer to listen
// to browsing data changes.
- (void)resetNTP;

@end

#endif  // IOS_CHROME_BROWSER_UI_BROWSER_VIEW_CONTROLLER_H_
