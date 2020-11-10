// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ios/chrome/browser/policy/reporting/report_scheduler_ios.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#include "base/bind_helpers.h"
#include "base/test/gmock_callback_support.h"
#include "base/test/metrics/histogram_tester.h"
#include "base/test/scoped_feature_list.h"
#include "base/threading/thread_task_runner_handle.h"
#include "components/enterprise/browser/controller/fake_browser_dm_token_storage.h"
#include "components/enterprise/browser/reporting/common_pref_names.h"
#include "components/policy/core/common/cloud/mock_cloud_policy_client.h"
#include "ios/chrome/browser/policy/reporting/reporting_delegate_factory_ios.h"
#include "ios/chrome/test/ios_chrome_scoped_testing_local_state.h"
#include "ios/web/public/test/web_task_environment.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/platform_test.h"

using ::base::test::RunOnceCallback;
using ::testing::_;
using ::testing::Invoke;
using ::testing::WithArgs;

namespace em = enterprise_management;

namespace enterprise_reporting {

namespace {

constexpr char kDMToken[] = "dm_token";
constexpr char kClientId[] = "client_id";
constexpr base::TimeDelta kDefaultUploadInterval =
    base::TimeDelta::FromHours(24);

}  // namespace

ACTION_P(ScheduleGeneratorCallback, request_number) {
  ReportGenerator::ReportRequests requests;
  for (int i = 0; i < request_number; i++)
    requests.push(std::make_unique<ReportGenerator::ReportRequest>());
  base::ThreadTaskRunnerHandle::Get()->PostTask(
      FROM_HERE, base::BindOnce(std::move(arg0), std::move(requests)));
}

class MockReportGenerator : public ReportGenerator {
 public:
  explicit MockReportGenerator(ReportingDelegateFactoryIOS* delegate_factory)
      : ReportGenerator(delegate_factory) {}
  MockReportGenerator(const MockReportGenerator&) = delete;
  MockReportGenerator& operator=(const MockReportGenerator&) = delete;

  void Generate(ReportType report_type, ReportCallback callback) override {
    OnGenerate(report_type, callback);
  }
  MOCK_METHOD2(OnGenerate,
               void(ReportType report_type, ReportCallback& callback));
  MOCK_METHOD0(GenerateBasic, ReportRequests());
};

class MockReportUploader : public ReportUploader {
 public:
  MockReportUploader() : ReportUploader(nullptr, 0) {}
  MockReportUploader(const MockReportUploader&) = delete;
  MockReportUploader& operator=(const MockReportUploader&) = delete;
  ~MockReportUploader() override = default;

  MOCK_METHOD2(SetRequestAndUpload, void(ReportRequests, ReportCallback));
};

class ReportSchedulerIOSTest : public PlatformTest {
 public:
  ReportSchedulerIOSTest()
      : task_environment_(web::WebTaskEnvironment::Options::DEFAULT,
                          base::test::TaskEnvironment::TimeSource::MOCK_TIME) {}
  ReportSchedulerIOSTest(const ReportSchedulerIOSTest&) = delete;
  ReportSchedulerIOSTest& operator=(const ReportSchedulerIOSTest&) = delete;
  ~ReportSchedulerIOSTest() override = default;

  void SetUp() override {
    client_ptr_ = std::make_unique<policy::MockCloudPolicyClient>();
    client_ = client_ptr_.get();
    generator_ptr_ =
        std::make_unique<MockReportGenerator>(&report_delegate_factory_);
    generator_ = generator_ptr_.get();
    uploader_ptr_ = std::make_unique<MockReportUploader>();
    uploader_ = uploader_ptr_.get();
    Init(true, kDMToken, kClientId);
  }

  void Init(bool policy_enabled,
            const std::string& dm_token,
            const std::string& client_id) {
    ToggleCloudReport(policy_enabled);
    storage_.SetDMToken(dm_token);
    storage_.SetClientId(client_id);
  }

  void CreateScheduler() {
    scheduler_ = std::make_unique<ReportScheduler>(
        client_, std::move(generator_ptr_), &report_delegate_factory_);
    scheduler_->SetReportUploaderForTesting(std::move(uploader_ptr_));
  }

  void SetLastUploadInHour(base::TimeDelta gap) {
    previous_set_last_upload_timestamp_ = base::Time::Now() - gap;
    local_state_.Get()->SetTime(kLastUploadTimestamp,
                                previous_set_last_upload_timestamp_);
  }

  void ToggleCloudReport(bool enabled) {
    local_state_.Get()->SetManagedPref(kCloudReportingEnabled,
                                       std::make_unique<base::Value>(enabled));
  }

  // If lastUploadTimestamp is updated recently, it should be updated as Now().
  // Otherwise, it should be same as previous set timestamp.
  void ExpectLastUploadTimestampUpdated(bool is_updated) {
    auto current_last_upload_timestamp =
        local_state_.Get()->GetTime(kLastUploadTimestamp);
    if (is_updated) {
      EXPECT_EQ(base::Time::Now(), current_last_upload_timestamp);
    } else {
      EXPECT_EQ(previous_set_last_upload_timestamp_,
                current_last_upload_timestamp);
    }
  }

  ReportGenerator::ReportRequests CreateRequests(int number) {
    ReportGenerator::ReportRequests requests;
    for (int i = 0; i < number; i++)
      requests.push(std::make_unique<ReportGenerator::ReportRequest>());
    return requests;
  }

  void EXPECT_CALL_SetupRegistration() {
    EXPECT_CALL(*client_, SetupRegistration(kDMToken, kClientId, _));
  }

  void EXPECT_CALL_SetupRegistrationWithSetDMToken() {
    EXPECT_CALL(*client_, SetupRegistration(kDMToken, kClientId, _))
        .WillOnce(WithArgs<0>(
            Invoke(client_, &policy::MockCloudPolicyClient::SetDMToken)));
  }

  base::test::ScopedFeatureList scoped_feature_list_;
  web::WebTaskEnvironment task_environment_;
  IOSChromeScopedTestingLocalState local_state_;

  ReportingDelegateFactoryIOS report_delegate_factory_;
  std::unique_ptr<ReportScheduler> scheduler_;
  policy::MockCloudPolicyClient* client_;
  MockReportGenerator* generator_;
  MockReportUploader* uploader_;
  policy::FakeBrowserDMTokenStorage storage_;
  base::Time previous_set_last_upload_timestamp_;
  base::HistogramTester histogram_tester_;

 private:
  std::unique_ptr<policy::MockCloudPolicyClient> client_ptr_;
  std::unique_ptr<MockReportGenerator> generator_ptr_;
  std::unique_ptr<MockReportUploader> uploader_ptr_;
};

TEST_F(ReportSchedulerIOSTest, NoReportWithoutPolicy) {
  Init(false, kDMToken, kClientId);
  CreateScheduler();
  EXPECT_FALSE(scheduler_->IsNextReportScheduledForTesting());
}

TEST_F(ReportSchedulerIOSTest, NoReportWithoutDMToken) {
  Init(true, "", kClientId);
  CreateScheduler();
  EXPECT_FALSE(scheduler_->IsNextReportScheduledForTesting());
}

TEST_F(ReportSchedulerIOSTest, NoReportWithoutClientId) {
  Init(true, kDMToken, "");
  CreateScheduler();
  EXPECT_FALSE(scheduler_->IsNextReportScheduledForTesting());
}

TEST_F(ReportSchedulerIOSTest, UploadReportSucceeded) {
  EXPECT_CALL_SetupRegistration();
  EXPECT_CALL(*generator_, OnGenerate(ReportType::kFull, _))
      .WillOnce(WithArgs<1>(ScheduleGeneratorCallback(1)));
  EXPECT_CALL(*uploader_, SetRequestAndUpload(_, _))
      .WillOnce(RunOnceCallback<1>(ReportUploader::kSuccess));

  CreateScheduler();
  EXPECT_TRUE(scheduler_->IsNextReportScheduledForTesting());

  // Run pending task.
  task_environment_.RunUntilIdle();

  // Next report is scheduled.
  EXPECT_TRUE(scheduler_->IsNextReportScheduledForTesting());
  ExpectLastUploadTimestampUpdated(true);

  ::testing::Mock::VerifyAndClearExpectations(client_);
  ::testing::Mock::VerifyAndClearExpectations(generator_);
}

TEST_F(ReportSchedulerIOSTest, UploadReportTransientError) {
  EXPECT_CALL_SetupRegistration();
  EXPECT_CALL(*generator_, OnGenerate(ReportType::kFull, _))
      .WillOnce(WithArgs<1>(ScheduleGeneratorCallback(1)));
  EXPECT_CALL(*uploader_, SetRequestAndUpload(_, _))
      .WillOnce(RunOnceCallback<1>(ReportUploader::kTransientError));

  CreateScheduler();
  EXPECT_TRUE(scheduler_->IsNextReportScheduledForTesting());

  // Run pending task.
  task_environment_.RunUntilIdle();

  // Next report is scheduled.
  EXPECT_TRUE(scheduler_->IsNextReportScheduledForTesting());
  ExpectLastUploadTimestampUpdated(true);

  ::testing::Mock::VerifyAndClearExpectations(client_);
  ::testing::Mock::VerifyAndClearExpectations(generator_);
}

TEST_F(ReportSchedulerIOSTest, UploadReportPersistentError) {
  EXPECT_CALL_SetupRegistrationWithSetDMToken();
  EXPECT_CALL(*generator_, OnGenerate(ReportType::kFull, _))
      .WillOnce(WithArgs<1>(ScheduleGeneratorCallback(1)));
  EXPECT_CALL(*uploader_, SetRequestAndUpload(_, _))
      .WillOnce(RunOnceCallback<1>(ReportUploader::kPersistentError));

  CreateScheduler();
  EXPECT_TRUE(scheduler_->IsNextReportScheduledForTesting());

  // Run pending task.
  task_environment_.RunUntilIdle();

  // Next report is not scheduled.
  EXPECT_FALSE(scheduler_->IsNextReportScheduledForTesting());
  ExpectLastUploadTimestampUpdated(false);

  // Turn off and on reporting to resume.
  ToggleCloudReport(false);
  ToggleCloudReport(true);
  EXPECT_TRUE(scheduler_->IsNextReportScheduledForTesting());

  ::testing::Mock::VerifyAndClearExpectations(client_);
  ::testing::Mock::VerifyAndClearExpectations(generator_);
}

TEST_F(ReportSchedulerIOSTest, NoReportGenerate) {
  EXPECT_CALL_SetupRegistrationWithSetDMToken();
  EXPECT_CALL(*generator_, OnGenerate(ReportType::kFull, _))
      .WillOnce(WithArgs<1>(ScheduleGeneratorCallback(0)));
  EXPECT_CALL(*uploader_, SetRequestAndUpload(_, _)).Times(0);

  CreateScheduler();
  EXPECT_TRUE(scheduler_->IsNextReportScheduledForTesting());

  // Run pending task.
  task_environment_.RunUntilIdle();

  // Next report is not scheduled.
  EXPECT_FALSE(scheduler_->IsNextReportScheduledForTesting());
  ExpectLastUploadTimestampUpdated(false);

  // Turn off and on reporting to resume.
  ToggleCloudReport(false);
  ToggleCloudReport(true);
  EXPECT_TRUE(scheduler_->IsNextReportScheduledForTesting());

  ::testing::Mock::VerifyAndClearExpectations(client_);
  ::testing::Mock::VerifyAndClearExpectations(generator_);
}

TEST_F(ReportSchedulerIOSTest, TimerDelayWithLastUploadTimestamp) {
  const base::TimeDelta gap = base::TimeDelta::FromHours(10);
  SetLastUploadInHour(gap);

  EXPECT_CALL_SetupRegistration();
  EXPECT_CALL(*generator_, OnGenerate(ReportType::kFull, _))
      .WillOnce(WithArgs<1>(ScheduleGeneratorCallback(1)));
  EXPECT_CALL(*uploader_, SetRequestAndUpload(_, _))
      .WillOnce(RunOnceCallback<1>(ReportUploader::kSuccess));

  CreateScheduler();
  EXPECT_TRUE(scheduler_->IsNextReportScheduledForTesting());

  base::TimeDelta next_report_delay = kDefaultUploadInterval - gap;
  task_environment_.FastForwardBy(next_report_delay -
                                  base::TimeDelta::FromSeconds(1));
  ExpectLastUploadTimestampUpdated(false);
  task_environment_.FastForwardBy(base::TimeDelta::FromSeconds(1));
  ExpectLastUploadTimestampUpdated(true);

  ::testing::Mock::VerifyAndClearExpectations(client_);
  ::testing::Mock::VerifyAndClearExpectations(generator_);
}

TEST_F(ReportSchedulerIOSTest, TimerDelayWithoutLastUploadTimestamp) {
  EXPECT_CALL_SetupRegistration();
  EXPECT_CALL(*generator_, OnGenerate(ReportType::kFull, _))
      .WillOnce(WithArgs<1>(ScheduleGeneratorCallback(1)));
  EXPECT_CALL(*uploader_, SetRequestAndUpload(_, _))
      .WillOnce(RunOnceCallback<1>(ReportUploader::kSuccess));

  CreateScheduler();
  EXPECT_TRUE(scheduler_->IsNextReportScheduledForTesting());

  ExpectLastUploadTimestampUpdated(false);
  task_environment_.RunUntilIdle();
  ExpectLastUploadTimestampUpdated(true);

  ::testing::Mock::VerifyAndClearExpectations(client_);
}

TEST_F(ReportSchedulerIOSTest,
       ReportingIsDisabledWhileNewReportIsScheduledButNotPosted) {
  EXPECT_CALL_SetupRegistration();

  CreateScheduler();
  EXPECT_TRUE(scheduler_->IsNextReportScheduledForTesting());

  // Run pending task.
  task_environment_.RunUntilIdle();

  ToggleCloudReport(false);

  // Next report is not scheduled.
  EXPECT_FALSE(scheduler_->IsNextReportScheduledForTesting());
  ExpectLastUploadTimestampUpdated(false);

  ::testing::Mock::VerifyAndClearExpectations(client_);
  ::testing::Mock::VerifyAndClearExpectations(generator_);
}

TEST_F(ReportSchedulerIOSTest, ReportingIsDisabledWhileNewReportIsPosted) {
  EXPECT_CALL_SetupRegistration();
  EXPECT_CALL(*generator_, OnGenerate(ReportType::kFull, _))
      .WillOnce(WithArgs<1>(ScheduleGeneratorCallback(1)));
  EXPECT_CALL(*uploader_, SetRequestAndUpload(_, _))
      .WillOnce(RunOnceCallback<1>(ReportUploader::kSuccess));

  CreateScheduler();
  EXPECT_TRUE(scheduler_->IsNextReportScheduledForTesting());

  // Run pending task.
  task_environment_.RunUntilIdle();

  ToggleCloudReport(false);

  // Run pending task.
  task_environment_.RunUntilIdle();

  ExpectLastUploadTimestampUpdated(true);
  // Next report is not scheduled.
  EXPECT_FALSE(scheduler_->IsNextReportScheduledForTesting());

  ::testing::Mock::VerifyAndClearExpectations(client_);
  ::testing::Mock::VerifyAndClearExpectations(generator_);
}

}  // namespace enterprise_reporting