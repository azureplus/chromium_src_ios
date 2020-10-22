// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_UI_AUTOFILL_MANUAL_FILL_MANUAL_FILL_CREDENTIAL_PASSWORDFORM_H_
#define IOS_CHROME_BROWSER_UI_AUTOFILL_MANUAL_FILL_MANUAL_FILL_CREDENTIAL_PASSWORDFORM_H_

#include "components/password_manager/core/browser/password_form_forward.h"
#import "ios/chrome/browser/ui/autofill/manual_fill/manual_fill_credential.h"

@interface ManualFillCredential (PasswordForm)

// Convenience initializer from a PasswordForm.
- (instancetype)initWithPasswordForm:
    (const password_manager::PasswordForm&)passwordForm;

@end

#endif  // IOS_CHROME_BROWSER_UI_AUTOFILL_MANUAL_FILL_MANUAL_FILL_CREDENTIAL_PASSWORDFORM_H_
