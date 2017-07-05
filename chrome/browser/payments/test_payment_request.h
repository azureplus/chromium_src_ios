// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_PAYMENTS_TEST_PAYMENT_REQUEST_H_
#define IOS_CHROME_BROWSER_PAYMENTS_TEST_PAYMENT_REQUEST_H_

#include "base/macros.h"
#include "ios/chrome/browser/payments/payment_request.h"

namespace autofill {
class PersonalDataManager;
class RegionDataLoader;
}  // namespace autofill

namespace ios {
class ChromeBrowserState;
}  // namespace ios

namespace payments {
class PaymentsProfileComparator;
}  // namespace payments

namespace web {
class PaymentRequest;
class PaymentShippingOption;
}  // namespace web

class PrefService;

// PaymentRequest for use in tests.
class TestPaymentRequest : public PaymentRequest {
 public:
  // |personal_data_manager| should not be null and should outlive this object.
  TestPaymentRequest(const web::PaymentRequest& web_payment_request,
                     ios::ChromeBrowserState* browser_state,
                     autofill::PersonalDataManager* personal_data_manager,
                     id<PaymentRequestUIDelegate> payment_request_ui_delegate)
      : PaymentRequest(web_payment_request,
                       browser_state,
                       personal_data_manager,
                       payment_request_ui_delegate),
        region_data_loader_(nullptr),
        pref_service_(nullptr),
        profile_comparator_(nullptr) {}

  TestPaymentRequest(const web::PaymentRequest& web_payment_request,
                     ios::ChromeBrowserState* browser_state,
                     autofill::PersonalDataManager* personal_data_manager)
      : TestPaymentRequest(web_payment_request,
                           browser_state,
                           personal_data_manager,
                           nil) {}

  TestPaymentRequest(const web::PaymentRequest& web_payment_request,
                     autofill::PersonalDataManager* personal_data_manager)
      : TestPaymentRequest(web_payment_request,
                           nil,
                           personal_data_manager,
                           nil) {}

  ~TestPaymentRequest() override {}

  void SetRegionDataLoader(autofill::RegionDataLoader* region_data_loader) {
    region_data_loader_ = region_data_loader;
  }

  void SetPrefService(PrefService* pref_service) {
    pref_service_ = pref_service;
  }

  void SetProfileComparator(
      payments::PaymentsProfileComparator* profile_comparator) {
    profile_comparator_ = profile_comparator;
  }

  // Returns the web::PaymentRequest instance that was used to build this
  // object.
  web::PaymentRequest& web_payment_request() { return web_payment_request_; }

  // Removes all the shipping profiles.
  void ClearShippingProfiles();

  // Removes all the contact profiles.
  void ClearContactProfiles();

  // Removes all the credit cards.
  void ClearCreditCards();

  // Sets the currently selected shipping option for this PaymentRequest flow.
  void set_selected_shipping_option(web::PaymentShippingOption* option) {
    selected_shipping_option_ = option;
  }

  // PaymentRequest
  autofill::RegionDataLoader* GetRegionDataLoader() override;
  PrefService* GetPrefService() override;
  payments::PaymentsProfileComparator* profile_comparator() override;

 private:
  // Not owned and must outlive this object.
  autofill::RegionDataLoader* region_data_loader_;

  // Not owned and must outlive this object.
  PrefService* pref_service_;

  // Not owned and must outlive this object.
  payments::PaymentsProfileComparator* profile_comparator_;

  DISALLOW_COPY_AND_ASSIGN(TestPaymentRequest);
};

#endif  // IOS_CHROME_BROWSER_PAYMENTS_TEST_PAYMENT_REQUEST_H_
