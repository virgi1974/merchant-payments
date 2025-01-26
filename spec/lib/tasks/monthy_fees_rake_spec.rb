require "rails_helper"
require "rake"

RSpec.describe "monthly_fees:process rake task" do
  include ActiveSupport::Testing::TimeHelpers

  let(:merchant_repository) { instance_double(Domain::Fees::Repositories::MerchantRepository) }
  let(:monthly_fee_tracker) { instance_double(Domain::Disbursements::Services::MonthlyFeeTracker) }
  let(:merchant) do
    instance_double(Domain::Merchants::Entities::DisbursableMerchant,
    id: 1,
    reference: "test_merchant",
    disbursement_frequency: "weekly",
    live_on: Date.new(2024, 1, 10), # Wednesday
    minimum_monthly_fee_cents: 2900)
  end

  before do
    Rails.application.load_tasks
    Rake::Task.define_task(:environment)
    allow(Domain::Fees::Repositories::MerchantRepository).to receive(:new).and_return(merchant_repository)
    allow(Domain::Disbursements::Services::MonthlyFeeTracker).to receive(:new).and_return(monthly_fee_tracker)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  context "when running on first day of month" do
    before do
      travel_to Time.zone.local(2024, 1, 1, 4, 0, 0) # First day of month at 4 AM
    end

    after { travel_back }

    it "processes monthly fees for all merchants" do
      allow(merchant_repository).to receive(:find_all_merchants_in_batches).and_return([ merchant ])
      allow(monthly_fee_tracker).to receive(:process_merchant).and_return(true)

      expect(Rails.logger).to receive(:info).with("Starting monthly fee processing at 2024-01-01 04:00:00 UTC").ordered
      expect(Rails.logger).to receive(:info).with("Processing fees for December 2023").ordered
      expect(Rails.logger).to receive(:info).with("Processing merchant test_merchant").ordered
      expect(Rails.logger).to receive(:info).with("Finished monthly fee processing at 2024-01-01 04:00:00 UTC").ordered
      expect(Rails.logger).to receive(:info).with("Monthly Fee Adjustments created: 1").ordered

      Rake::Task["monthly_fees:process"].invoke
    end

    it "logs progress" do
      allow(merchant_repository).to receive(:find_all_merchants_in_batches).and_return([ merchant ])
      allow(monthly_fee_tracker).to receive(:process_merchant)

      expect(Rails.logger).to receive(:info).with(/Starting monthly fee processing/)
      expect(Rails.logger).to receive(:info).with(/Processing fees for December 2023/)
      expect(Rails.logger).to receive(:info).with(/Processing merchant test_merchant/)
      expect(Rails.logger).to receive(:info).with(/Finished monthly fee processing/)

      Rake::Task["monthly_fees:process"].invoke
    end

    context "when an error occurs" do
      before do
        error = StandardError.new("Test error")
        allow(merchant_repository).to receive(:find_all_merchants_in_batches).and_raise(error)
      end

      it "logs error and re-raises" do
        expect(Rails.logger).to receive(:error).with("Error processing monthly fees: Test error")
        expect { Rake::Task["monthly_fees:process"].invoke }.to raise_error(StandardError, "Test error")
      end
    end
  end

  context "when not running on first day of month" do
    before do
      travel_to Time.zone.local(2024, 1, 2, 4, 0, 0) # Second day of month
    end

    after { travel_back }

    it "skips processing" do
      expect(merchant_repository).not_to receive(:find_all_merchants_in_batches)
      expect(monthly_fee_tracker).not_to receive(:process_merchant)
      expect(Rails.logger).to receive(:info).with(/Skipping monthly fee processing/)

      Rake::Task["monthly_fees:process"].invoke
    end
  end

  after do
    Rake::Task["monthly_fees:process"].reenable
  end
end
