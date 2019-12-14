// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/ui/bookmarks/bookmark_earl_grey.h"

#import <Foundation/Foundation.h>

#include "base/strings/sys_string_conversions.h"
#import "ios/chrome/browser/ui/bookmarks/bookmark_earl_grey_app_interface.h"
#import "ios/testing/earl_grey/earl_grey_test.h"
#import "ios/web/public/test/http_server/http_server.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#if defined(CHROME_EARL_GREY_2)
// TODO(crbug.com/1015113): The EG2 macro is breaking indexing for some reason
// without the trailing semicolon.  For now, disable the extra semi warning
// so Xcode indexing works for the egtest.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wc++98-compat-extra-semi"
GREY_STUB_CLASS_IN_APP_MAIN_QUEUE(BookmarkEarlGreyAppInterface);
#pragma clang diagnostic pop
#endif  // defined(CHROME_EARL_GREY_2)

const GURL GetFirstUrl() {
  return web::test::HttpServer::MakeUrl(
      "http://ios/testing/data/http_server_files/pony.html");
}

const GURL GetSecondUrl() {
  return web::test::HttpServer::MakeUrl(
      "http://ios/testing/data/http_server_files/destination.html");
}

const GURL GetFrenchUrl() {
  return web::test::HttpServer::MakeUrl("http://www.a.fr/");
}

@implementation BookmarkEarlGreyImpl

- (void)clearBookmarksPositionCache {
  [BookmarkEarlGreyAppInterface clearBookmarksPositionCache];
}

- (void)setupStandardBookmarks {
  const GURL fourthURL = web::test::HttpServer::MakeUrl(
      "http://ios/testing/data/http_server_files/chromium_logo_page.html");

  NSString* spec1 = base::SysUTF8ToNSString(GetFirstUrl().spec());
  NSString* spec2 = base::SysUTF8ToNSString(GetSecondUrl().spec());
  NSString* spec3 = base::SysUTF8ToNSString(GetFrenchUrl().spec());
  NSString* spec4 = base::SysUTF8ToNSString(fourthURL.spec());
  EG_TEST_HELPER_ASSERT_NO_ERROR([BookmarkEarlGreyAppInterface
      setupStandardBookmarksUsingFirstURL:spec1
                                secondURL:spec2
                                 thirdURL:spec3
                                fourthURL:spec4]);
}

@end