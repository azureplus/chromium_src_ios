// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ios/web_view/internal/passwords/web_view_password_feature_manager.h"

#include "base/logging.h"
#include "components/password_manager/core/browser/password_manager_features_util.h"
#include "components/prefs/pref_service.h"
#include "components/sync/driver/sync_service.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

namespace ios_web_view {
WebViewPasswordFeatureManager::WebViewPasswordFeatureManager(
    PrefService* pref_service,
    const syncer::SyncService* sync_service)
    : pref_service_(pref_service), sync_service_(sync_service) {}

bool WebViewPasswordFeatureManager::IsGenerationEnabled() const {
  return false;
}

bool WebViewPasswordFeatureManager::IsOptedInForAccountStorage() const {
  // Although ios/web_view will only write to the account store, this should
  // still be controlled on a per user basis to ensure that the logged out user
  // remains opted out.
  return password_manager::features_util::IsOptedInForAccountStorage(
      pref_service_, sync_service_);
}

bool WebViewPasswordFeatureManager::ShouldShowAccountStorageOptIn() const {
  return false;
}

bool WebViewPasswordFeatureManager::ShouldShowAccountStorageReSignin() const {
  return false;
}

void WebViewPasswordFeatureManager::OptInToAccountStorage() {
  NOTREACHED();
}

void WebViewPasswordFeatureManager::OptOutOfAccountStorageAndClearSettings() {
  NOTREACHED();
}

bool WebViewPasswordFeatureManager::ShouldShowPasswordStorePicker() const {
  return false;
}

autofill::PasswordForm::Store
WebViewPasswordFeatureManager::GetDefaultPasswordStore() const {
  // ios/web_view should never write to the profile password store.
  return autofill::PasswordForm::Store::kAccountStore;
}

void WebViewPasswordFeatureManager::SetDefaultPasswordStore(
    const autofill::PasswordForm::Store& store) {
  NOTREACHED();
}

}  // namespace ios_web_view
