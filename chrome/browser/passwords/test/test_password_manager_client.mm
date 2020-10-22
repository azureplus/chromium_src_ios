// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/passwords/test/test_password_manager_client.h"

#include "components/password_manager/core/browser/password_form_manager_for_ui.h"
#include "components/password_manager/core/browser/test_password_store.h"
#include "components/password_manager/core/common/password_manager_pref_names.h"
#include "components/prefs/pref_registry_simple.h"
#include "components/prefs/testing_pref_service.h"
#include "components/safe_browsing/core/common/safe_browsing_prefs.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

namespace {
// HTTPS origin corresponding to kHostName.
constexpr char kHttpsWebOrigin[] = "https://www.example.com/";
}  // namespace

TestPasswordManagerClient::TestPasswordManagerClient()
    : last_committed_url_(kHttpsWebOrigin), password_manager_(this) {
  store_ = base::MakeRefCounted<TestPasswordStore>();
  store_->Init(nullptr);
  prefs_ = std::make_unique<TestingPrefServiceSimple>();
  prefs_->registry()->RegisterBooleanPref(
      password_manager::prefs::kCredentialsEnableAutosignin, true);
  prefs_->registry()->RegisterBooleanPref(
      password_manager::prefs::kWasAutoSignInFirstRunExperienceShown, true);
  prefs_->registry()->RegisterBooleanPref(
      password_manager::prefs::kPasswordLeakDetectionEnabled, true);
  prefs_->registry()->RegisterBooleanPref(::prefs::kSafeBrowsingEnabled, true);
  prefs_->registry()->RegisterBooleanPref(::prefs::kSafeBrowsingEnhanced, true);
}

TestPasswordManagerClient::~TestPasswordManagerClient() = default;

scoped_refptr<TestPasswordStore> TestPasswordManagerClient::password_store()
    const {
  return store_;
}

void TestPasswordManagerClient::set_password_store(
    scoped_refptr<TestPasswordStore> store) {
  store_ = store;
}

PasswordFormManagerForUI* TestPasswordManagerClient::pending_manager() const {
  return manager_.get();
}

void TestPasswordManagerClient::set_current_url(const GURL& current_url) {
  last_committed_url_ = current_url;
}

// Private Methods

PrefService* TestPasswordManagerClient::GetPrefs() const {
  return prefs_.get();
}

PasswordStore* TestPasswordManagerClient::GetProfilePasswordStore() const {
  return store_.get();
}

const PasswordManager* TestPasswordManagerClient::GetPasswordManager() const {
  return &password_manager_;
}

url::Origin TestPasswordManagerClient::GetLastCommittedOrigin() const {
  return url::Origin::Create(last_committed_url_);
}

bool TestPasswordManagerClient::PromptUserToSaveOrUpdatePassword(
    std::unique_ptr<PasswordFormManagerForUI> manager,
    bool update_password) {
  EXPECT_FALSE(update_password);
  manager_.swap(manager);
  PromptUserToSavePasswordPtr(manager_.get());
  return true;
}

bool TestPasswordManagerClient::PromptUserToChooseCredentials(
    std::vector<std::unique_ptr<password_manager::PasswordForm>> local_forms,
    const url::Origin& origin,
    CredentialsCallback callback) {
  EXPECT_FALSE(local_forms.empty());
  const password_manager::PasswordForm* form = local_forms[0].get();
  base::SequencedTaskRunnerHandle::Get()->PostTask(
      FROM_HERE,
      base::BindOnce(std::move(callback),
                     base::Owned(new password_manager::PasswordForm(*form))));
  std::vector<password_manager::PasswordForm*> raw_forms(local_forms.size());
  std::transform(
      local_forms.begin(), local_forms.end(), raw_forms.begin(),
      [](const std::unique_ptr<password_manager::PasswordForm>& form) {
        return form.get();
      });
  PromptUserToChooseCredentialsPtr(raw_forms, origin, base::DoNothing());
  return true;
}
