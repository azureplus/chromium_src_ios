// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ios/chrome/browser/payments/payment_request_test_util.h"

#include "base/strings/utf_string_conversions.h"
#include "components/payments/core/payment_method_data.h"
#include "ios/web/public/payments/payment_request.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

namespace payment_request_test_util {

web::PaymentRequest CreateTestWebPaymentRequest() {
  web::PaymentRequest web_payment_request;
  payments::PaymentMethodData method_datum;
  method_datum.supported_methods.push_back("visa");
  method_datum.supported_methods.push_back("amex");
  web_payment_request.method_data.push_back(method_datum);
  web_payment_request.details.total.label = base::ASCIIToUTF16("Total");
  web_payment_request.details.total.amount.value = base::ASCIIToUTF16("1.00");
  web_payment_request.details.total.amount.currency = base::ASCIIToUTF16("USD");
  web::PaymentItem display_item;
  display_item.label = base::ASCIIToUTF16("Subtotal");
  display_item.amount.value = base::ASCIIToUTF16("1.00");
  display_item.amount.currency = base::ASCIIToUTF16("USD");
  web_payment_request.details.display_items.push_back(display_item);
  web::PaymentShippingOption shipping_option;
  shipping_option.id = base::ASCIIToUTF16("123456");
  shipping_option.label = base::ASCIIToUTF16("1-Day");
  shipping_option.amount.value = base::ASCIIToUTF16("0.99");
  shipping_option.amount.currency = base::ASCIIToUTF16("USD");
  shipping_option.selected = true;
  web_payment_request.details.shipping_options.push_back(shipping_option);
  web::PaymentShippingOption shipping_option2;
  shipping_option2.id = base::ASCIIToUTF16("654321");
  shipping_option2.label = base::ASCIIToUTF16("10-Days");
  shipping_option2.amount.value = base::ASCIIToUTF16("0.01");
  shipping_option2.amount.currency = base::ASCIIToUTF16("USD");
  shipping_option2.selected = false;
  web_payment_request.details.shipping_options.push_back(shipping_option2);
  web_payment_request.options.request_shipping = true;
  return web_payment_request;
}

}  // namespace payment_request_test_util
