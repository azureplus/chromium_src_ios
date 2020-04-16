// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ios/chrome/browser/metrics/metrics_app_interface.h"

#include <memory>
#include <string>

#include "base/stl_util.h"
#include "base/strings/sys_string_conversions.h"
#import "base/test/ios/wait_util.h"
#include "components/metrics/metrics_service.h"
#include "components/metrics/test/demographic_metrics_test_utils.h"
#include "components/metrics_services_manager/metrics_services_manager.h"
#include "components/network_time/network_time_tracker.h"
#include "components/ukm/ukm_service.h"
#include "components/ukm/ukm_test_helper.h"
#include "ios/chrome/browser/application_context.h"
#include "ios/chrome/browser/browser_state/chrome_browser_state.h"
#include "ios/chrome/browser/browser_state/chrome_browser_state_manager.h"
#include "ios/chrome/browser/metrics/ios_chrome_metrics_service_accessor.h"
#import "ios/chrome/test/app/histogram_test_util.h"
#import "ios/testing/nserror_util.h"
#include "third_party/metrics_proto/chrome_user_metrics_extension.pb.h"
#include "third_party/metrics_proto/ukm/report.pb.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

namespace {

bool g_metrics_enabled = false;

chrome_test_util::HistogramTester* g_histogram_tester = nullptr;

PrefService* GetProfilePrefs() {
  return GetApplicationContext()
      ->GetChromeBrowserStateManager()
      ->GetLastUsedBrowserState()
      ->GetPrefs();
}

ukm::UkmService* GetUkmService() {
  return GetApplicationContext()->GetMetricsServicesManager()->GetUkmService();
}

metrics::MetricsService* GetMetricsService() {
  return GetApplicationContext()->GetMetricsService();
}

}  // namespace

@implementation MetricsAppInterface : NSObject

+ (void)overrideMetricsAndCrashReportingForTesting {
  IOSChromeMetricsServiceAccessor::SetMetricsAndCrashReportingForTesting(
      &g_metrics_enabled);
}

+ (void)stopOverridingMetricsAndCrashReportingForTesting {
  IOSChromeMetricsServiceAccessor::SetMetricsAndCrashReportingForTesting(
      nullptr);
}

+ (BOOL)setMetricsAndCrashReportingForTesting:(BOOL)enabled {
  BOOL previousValue = g_metrics_enabled;
  g_metrics_enabled = enabled;
  GetApplicationContext()->GetMetricsServicesManager()->UpdateUploadPermissions(
      true);
  return previousValue;
}

+ (BOOL)checkUKMRecordingEnabled:(BOOL)enabled {
  ukm::UkmTestHelper ukm_test_helper(GetUkmService());

  ConditionBlock condition = ^{
    return ukm_test_helper.IsRecordingEnabled() == enabled;
  };
  return base::test::ios::WaitUntilConditionOrTimeout(
      syncher::kSyncUKMOperationsTimeout, condition);
}

+ (BOOL)isReportUserNoisedUserBirthYearAndGenderEnabled {
  return ukm::UkmTestHelper::IsReportUserNoisedUserBirthYearAndGenderEnabled();
}

+ (uint64_t)UKMClientID {
  ukm::UkmTestHelper ukm_test_helper(GetUkmService());
  return ukm_test_helper.GetClientId();
}

+ (BOOL)UKMHasDummySource:(int64_t)sourceID {
  ukm::UkmTestHelper ukm_test_helper(GetUkmService());
  return ukm_test_helper.HasSource(sourceID);
}

+ (void)UKMRecordDummySource:(int64_t)sourceID {
  ukm::UkmTestHelper ukm_test_helper(GetUkmService());
  ukm_test_helper.RecordSourceForTesting(sourceID);
}

+ (void)updateNetworkTime:(base::Time)now {
  metrics::test::UpdateNetworkTime(
      now, GetApplicationContext()->GetNetworkTimeTracker());
}

+ (int)maximumEligibleBirthYearForTime:(base::Time)now {
  return metrics::test::GetMaximumEligibleBirthYear(now);
}

+ (void)buildAndStoreUKMLog {
  ukm::UkmTestHelper ukm_test_helper(GetUkmService());
  ukm_test_helper.BuildAndStoreLog();
}

+ (BOOL)hasUnsentUKMLogs {
  ukm::UkmTestHelper ukm_test_helper(GetUkmService());
  return ukm_test_helper.HasUnsentLogs();
}

+ (BOOL)UKMReportHasBirthYear:(int)year
                       gender:(metrics::UserDemographicsProto::Gender)gender {
  ukm::UkmTestHelper ukm_test_helper(GetUkmService());
  std::unique_ptr<ukm::Report> report = ukm_test_helper.GetUkmReport();
  int noisedBirthYear =
      metrics::test::GetNoisedBirthYear(*GetProfilePrefs(), year);

  return report && gender == report->user_demographics().gender() &&
         noisedBirthYear == report->user_demographics().birth_year();
}

+ (BOOL)UKMReportHasUserDemographics {
  ukm::UkmTestHelper ukm_test_helper(GetUkmService());
  std::unique_ptr<ukm::Report> report = ukm_test_helper.GetUkmReport();
  return report && report->has_user_demographics();
}

+ (void)buildAndStoreUMALog {
  metrics::test::BuildAndStoreLog(GetMetricsService());
}

+ (BOOL)hasUnsentUMALogs {
  return metrics::test::HasUnsentLogs(GetMetricsService());
}

+ (BOOL)UMALogHasBirthYear:(int)year
                    gender:(metrics::UserDemographicsProto::Gender)gender {
  if (![self UMALogHasUserDemographics]) {
    return NO;
  }
  std::unique_ptr<metrics::ChromeUserMetricsExtension> log =
      metrics::test::GetLastUmaLog(GetMetricsService());
  int noisedBirthYear =
      metrics::test::GetNoisedBirthYear(*GetProfilePrefs(), year);

  return noisedBirthYear == log->user_demographics().birth_year() &&
         gender == log->user_demographics().gender();
}

+ (BOOL)UMALogHasUserDemographics {
  if (![self hasUnsentUMALogs]) {
    return NO;
  }
  std::unique_ptr<metrics::ChromeUserMetricsExtension> log =
      metrics::test::GetLastUmaLog(GetMetricsService());
  return log && log->has_user_demographics();
}

+ (NSError*)setupHistogramTester {
  if (g_histogram_tester) {
    return testing::NSErrorWithLocalizedDescription(
        @"Cannot setup two histogram testers.");
  }
  g_histogram_tester = new chrome_test_util::HistogramTester();
  return nil;
}

+ (NSError*)releaseHistogramTester {
  if (!g_histogram_tester) {
    return testing::NSErrorWithLocalizedDescription(
        @"Cannot release histogram tester.");
  }
  delete g_histogram_tester;
  g_histogram_tester = nullptr;
  return nil;
}

+ (NSError*)expectTotalCount:(int)count forHistogram:(NSString*)histogram {
  if (!g_histogram_tester) {
    return testing::NSErrorWithLocalizedDescription(
        @"setupHistogramTester must be called before testing metrics.");
  }
  __block NSString* error = nil;

  g_histogram_tester->ExpectTotalCount(base::SysNSStringToUTF8(histogram),
                                       count, ^(NSString* e) {
                                         error = e;
                                       });
  if (error) {
    return testing::NSErrorWithLocalizedDescription(error);
  }
  return nil;
}

+ (NSError*)expectCount:(int)count
              forBucket:(int)bucket
           forHistogram:(NSString*)histogram {
  if (!g_histogram_tester) {
    return testing::NSErrorWithLocalizedDescription(
        @"setupHistogramTester must be called before testing metrics.");
  }
  __block NSString* error = nil;

  g_histogram_tester->ExpectBucketCount(base::SysNSStringToUTF8(histogram),
                                        bucket, count, ^(NSString* e) {
                                          error = e;
                                        });
  if (error) {
    return testing::NSErrorWithLocalizedDescription(error);
  }
  return nil;
}

+ (NSError*)expectUniqueSampleWithCount:(int)count
                              forBucket:(int)bucket
                           forHistogram:(NSString*)histogram {
  if (!g_histogram_tester) {
    return testing::NSErrorWithLocalizedDescription(
        @"setupHistogramTester must be called before testing metrics.");
  }
  __block NSString* error = nil;

  g_histogram_tester->ExpectUniqueSample(base::SysNSStringToUTF8(histogram),
                                         bucket, count, ^(NSString* e) {
                                           error = e;
                                         });
  if (error) {
    return testing::NSErrorWithLocalizedDescription(error);
  }
  return nil;
}

+ (NSError*)expectSum:(NSInteger)sum forHistogram:(NSString*)histogram {
  if (!g_histogram_tester) {
    return testing::NSErrorWithLocalizedDescription(
        @"setupHistogramTester must be called before testing metrics.");
  }
  std::unique_ptr<base::HistogramSamples> samples =
      g_histogram_tester->GetHistogramSamplesSinceCreation(
          base::SysNSStringToUTF8(histogram));
  if (samples->sum() != sum) {
    return testing::NSErrorWithLocalizedDescription([NSString
        stringWithFormat:
            @"Sum of histogram %@ mismatch. Expected %ld, Observed: %ld",
            histogram, static_cast<long>(sum),
            static_cast<long>(samples->sum())]);
  }
  return nil;
}

@end
