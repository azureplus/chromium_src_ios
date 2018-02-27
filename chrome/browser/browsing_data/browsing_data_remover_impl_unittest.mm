// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/browsing_data/browsing_data_remover_impl.h"

#include <memory>

#include "base/logging.h"
#import "base/mac/bind_objc_block.h"
#include "base/macros.h"
#include "base/run_loop.h"
#include "components/open_from_clipboard/clipboard_recent_content.h"
#include "components/open_from_clipboard/fake_clipboard_recent_content.h"
#include "ios/chrome/browser/browser_state/test_chrome_browser_state.h"
#import "ios/chrome/browser/sessions/session_service_ios.h"
#import "ios/testing/wait_util.h"
#include "ios/web/public/test/test_web_thread_bundle.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/platform_test.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

namespace {

// Flags passed when calling Remove(). Clear as much data as possible, avoiding
// using services that are not created for TestChromeBrowserState.
constexpr BrowsingDataRemoveMask kRemoveMask =
    BrowsingDataRemoveMask::REMOVE_APPCACHE |
    BrowsingDataRemoveMask::REMOVE_CACHE |
    BrowsingDataRemoveMask::REMOVE_COOKIES |
    BrowsingDataRemoveMask::REMOVE_FORM_DATA |
    BrowsingDataRemoveMask::REMOVE_HISTORY |
    BrowsingDataRemoveMask::REMOVE_INDEXEDDB |
    BrowsingDataRemoveMask::REMOVE_LOCAL_STORAGE |
    BrowsingDataRemoveMask::REMOVE_PASSWORDS |
    BrowsingDataRemoveMask::REMOVE_WEBSQL |
    BrowsingDataRemoveMask::REMOVE_CHANNEL_IDS |
    BrowsingDataRemoveMask::REMOVE_CACHE_STORAGE |
    BrowsingDataRemoveMask::REMOVE_VISITED_LINKS |
    BrowsingDataRemoveMask::REMOVE_LAST_USER_ACCOUNT;

}  // namespace

class BrowsingDataRemoverImplTest : public PlatformTest {
 public:
  BrowsingDataRemoverImplTest()
      : browser_state_(TestChromeBrowserState::Builder().Build()),
        browsing_data_remover_(browser_state_.get(), nil) {
    DCHECK_EQ(ClipboardRecentContent::GetInstance(), nullptr);
    ClipboardRecentContent::SetInstance(
        std::make_unique<FakeClipboardRecentContent>());
  }

  ~BrowsingDataRemoverImplTest() override {
    DCHECK_NE(ClipboardRecentContent::GetInstance(), nullptr);
    ClipboardRecentContent::SetInstance(nullptr);
    browsing_data_remover_.Shutdown();
  }

 protected:
  web::TestWebThreadBundle thread_bundle_;
  std::unique_ptr<ios::ChromeBrowserState> browser_state_;
  BrowsingDataRemoverImpl browsing_data_remover_;

 private:
  DISALLOW_COPY_AND_ASSIGN(BrowsingDataRemoverImplTest);
};

// Tests that BrowsingDataRemoverImpl::Remove() can be called multiple times.
TEST_F(BrowsingDataRemoverImplTest, SerializeRemovals) {
  __block int remaining_calls = 2;
  browsing_data_remover_.Remove(browsing_data::TimePeriod::ALL_TIME,
                                kRemoveMask, base::BindBlockArc(^{
                                  --remaining_calls;
                                }));
  browsing_data_remover_.Remove(browsing_data::TimePeriod::ALL_TIME,
                                kRemoveMask, base::BindBlockArc(^{
                                  --remaining_calls;
                                }));

  EXPECT_TRUE(
      testing::WaitUntilConditionOrTimeout(testing::kWaitForActionTimeout, ^{
        // Spin the RunLoop as WaitUntilConditionOrTimeout doesn't.
        base::RunLoop().RunUntilIdle();
        return remaining_calls == 0;
      }));
}

// Tests that BrowsingDataRemoverImpl::Remove() can finish performing its
// operation even if the BrowserState is destroyed.
TEST_F(BrowsingDataRemoverImplTest, PerformAfterBrowserStateDestruction) {
  __block int remaining_calls = 1;
  browsing_data_remover_.Remove(browsing_data::TimePeriod::ALL_TIME,
                                kRemoveMask, base::BindBlockArc(^{
                                  --remaining_calls;
                                }));

  // Simulate destruction of BrowserState.
  browsing_data_remover_.Shutdown();

  EXPECT_TRUE(
      testing::WaitUntilConditionOrTimeout(testing::kWaitForActionTimeout, ^{
        // Spin the RunLoop as WaitUntilConditionOrTimeout doesn't.
        base::RunLoop().RunUntilIdle();
        return remaining_calls == 0;
      }));
}
