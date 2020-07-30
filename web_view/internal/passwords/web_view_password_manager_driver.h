// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_WEB_VIEW_INTERNAL_PASSWORDS_WEB_VIEW_PASSWORD_MANAGER_DRIVER_H_
#define IOS_WEB_VIEW_INTERNAL_PASSWORDS_WEB_VIEW_PASSWORD_MANAGER_DRIVER_H_

#import <Foundation/Foundation.h>
#include <vector>

#include "base/macros.h"
#include "components/autofill/core/common/password_form_fill_data.h"
#include "components/password_manager/core/browser/password_manager.h"
#include "components/password_manager/core/browser/password_manager_driver.h"
#include "components/password_manager/ios/password_manager_driver_bridge.h"

namespace ios_web_view {
// An //ios/web_view implementation of password_manager::PasswordManagerDriver.
class WebViewPasswordManagerDriver
    : public password_manager::PasswordManagerDriver {
 public:
  explicit WebViewPasswordManagerDriver(
      password_manager::PasswordManager* password_manager);
  ~WebViewPasswordManagerDriver() override;

  // password_manager::PasswordManagerDriver implementation.
  int GetId() const override;
  void FillPasswordForm(
      const autofill::PasswordFormFillData& form_data) override;
  void InformNoSavedCredentials(
      bool should_show_popup_without_passwords) override;
  void GeneratedPasswordAccepted(const base::string16& password) override;
  void FillSuggestion(const base::string16& username,
                      const base::string16& password) override;
  void PreviewSuggestion(const base::string16& username,
                         const base::string16& password) override;
  void ClearPreviewedForm() override;
  password_manager::PasswordGenerationFrameHelper* GetPasswordGenerationHelper()
      override;
  password_manager::PasswordManager* GetPasswordManager() override;
  password_manager::PasswordAutofillManager* GetPasswordAutofillManager()
      override;
  autofill::AutofillDriver* GetAutofillDriver() override;
  bool IsMainFrame() const override;
  bool CanShowAutofillUi() const override;
  const GURL& GetLastCommittedURL() const override;

  void set_bridge(id<PasswordManagerDriverBridge> bridge) { bridge_ = bridge; }

 private:
  __weak id<PasswordManagerDriverBridge> bridge_;

  password_manager::PasswordManager* password_manager_;

  DISALLOW_COPY_AND_ASSIGN(WebViewPasswordManagerDriver);
};
}  // namespace ios_web_view

#endif  // IOS_WEB_VIEW_INTERNAL_PASSWORDS_WEB_VIEW_PASSWORD_MANAGER_DRIVER_H_
