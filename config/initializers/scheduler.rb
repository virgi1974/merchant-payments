require "rufus-scheduler"

scheduler = Rufus::Scheduler.singleton

unless defined?(Rails::Console) || Rails.env.test? || File.split($PROGRAM_NAME).last == "rake"
  scheduler.cron "0 5 * * *" do # Runs every day at 5:00 AM
    Domain::Disbursements::Jobs::DisbursementCreationJob.perform_later
  end

  scheduler.cron "0 4 1 * *" do # 4 AM on 1st of each month
    Domain::Fees::Jobs::MonthlyFeeProcessingJob.perform_later
  end
end
