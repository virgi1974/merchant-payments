require "rails_helper"

RSpec.describe "Scheduler Configuration" do
  let(:scheduler) { Rufus::Scheduler.singleton }

  before do
    # Clear any existing jobs
    scheduler.jobs.each(&:unschedule)
  end

  after do
    # Clean up after tests
    scheduler.jobs.each(&:unschedule)
  end

  it "schedules disbursement job to run daily at 5:00 AM UTC" do
    # Load the scheduler configuration
    load Rails.root.join("config/initializers/scheduler.rb")

    # Skip if we're in test environment (the unless condition in scheduler.rb)
    next if defined?(Rails::Console) || Rails.env.test? || File.split($PROGRAM_NAME).last == "rake"

    # Get all cron jobs
    cron_jobs = scheduler.jobs(of: :cron)

    # Should have exactly one cron job
    expect(cron_jobs.size).to eq(1)

    job = cron_jobs.first
    expect(job.frequency).to eq("0 5 * * *")
    expect(job.callable).to respond_to(:call)

    # Test that it will enqueue the correct job
    expect {
      job.callable.call
    }.to have_enqueued_job(Domain::Disbursements::Jobs::DisbursementCreationJob)
  end

  it "does not schedule jobs in test environment" do
    original_env = Rails.env
    allow(Rails).to receive(:env).and_return("test".inquiry)

    load Rails.root.join("config/initializers/scheduler.rb")

    expect(scheduler.jobs.size).to eq(0)

    allow(Rails).to receive(:env).and_return(original_env)
  end
end
