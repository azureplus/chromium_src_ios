// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ios/chrome/browser/browser_about_rewriter.h"

#include <string>

#include "base/logging.h"
#include "components/url_formatter/url_fixer.h"
#include "ios/chrome/browser/chrome_url_constants.h"
#include "url/url_constants.h"

namespace {

const struct HostReplacement {
  const char* old_host_name;
  const char* new_host_name;
} kHostReplacements[] = {
    {"about", kChromeUIChromeURLsHost},
    {"sync", kChromeUISyncInternalsHost},
};

}  // namespace

bool WillHandleWebBrowserAboutURL(GURL* url, web::BrowserState* browser_state) {
  // Ensure that any cleanup done by FixupURL happens before the rewriting
  // phase that determines the virtual URL, by including it in an initial
  // URLHandler.  This prevents minor changes from producing a virtual URL,
  // which could lead to a URL spoof.
  *url = url_formatter::FixupURL(url->possibly_invalid_spec(), std::string());

  // Check that about: URLs are fixed up to chrome: by url_formatter::FixupURL.
  DCHECK((*url == url::kAboutBlankURL) || !url->SchemeIs(url::kAboutScheme));

  // url_formatter::FixupURL translates about:foo into chrome://foo/.
  if (!url->SchemeIs(kChromeUIScheme))
    return false;

  std::string host(url->host());
  for (size_t i = 0; i < arraysize(kHostReplacements); ++i) {
    if (host != kHostReplacements[i].old_host_name)
      continue;

    host.assign(kHostReplacements[i].new_host_name);
    break;
  }

  GURL::Replacements replacements;
  replacements.SetHostStr(host);
  *url = url->ReplaceComponents(replacements);

  // Having re-written the URL, make the chrome: handler process it.
  return false;
}
