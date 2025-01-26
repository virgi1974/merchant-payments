require "rails_helper"

RSpec.describe "Scheduler Configuration", type: :config do
  let(:scheduler) { Rufus::Scheduler.singleton }

  before do
    scheduler.jobs.each(&:unschedule)
  end

  after do
    scheduler.jobs.each(&:unschedule)
  end

  context "when in production environment" do
    before do
      allow(Rails).to receive(:env).and_return("production".inquiry)
      allow(File).to receive(:split).and_return([ "not_rake" ])
      load Rails.root.join("config/initializers/scheduler.rb")
    end

    it "schedules disbursement job to run daily at 5:00 AM UTC" do
      disbursement_job = scheduler.jobs(of: :cron).find { |job| job.original == "0 5 * * *" }
      expect(disbursement_job).to be_present
      expect(disbursement_job.callable).to respond_to(:call)
      expect {
        disbursement_job.callable.call
      }.to have_enqueued_job(Domain::Disbursements::Jobs::DisbursementCreationJob)
    end

    it "schedules monthly fees adjustment job to run the first day of each month at 4:00 AM UTC" do
      monthly_fee_job = scheduler.jobs(of: :cron).find { |job| job.original == "0 4 1 * *" }
      expect(monthly_fee_job).to be_present
      expect(monthly_fee_job.callable).to respond_to(:call)
      expect {
        monthly_fee_job.callable.call
      }.to have_enqueued_job(Domain::Fees::Jobs::MonthlyFeeProcessingJob)
    end
  end

  context "when in test environment" do
    it "does not schedule any jobs" do
      original_env = Rails.env
      allow(Rails).to receive(:env).and_return("test".inquiry)

      load Rails.root.join("config/initializers/scheduler.rb")

      expect(scheduler.jobs.size).to eq(0)

      allow(Rails).to receive(:env).and_return(original_env)
    end
  end
end
