require "rails_helper"

RSpec.describe "monthly_fees:process" do
  include_context "rake"
  include ActiveSupport::Testing::TimeHelpers

  let(:merchant_repository) { instance_double(Domain::Fees::Repositories::MerchantRepository) }
  let(:monthly_fee_tracker) { instance_double(Domain::Fees::Services::MonthlyFeeTracker) }
  let(:merchant) do
    instance_double(Domain::Merchants::Entities::DisbursableMerchant,
      id: 1,
      reference: "test_merchant",
      disbursement_frequency: "weekly",
      live_on: Date.new(2024, 1, 10),
      minimum_monthly_fee_cents: 2900)
  end

  before do
    Rake.application.rake_require("monthly_fees", [Rails.root.join("lib/tasks").to_s])
    Rake::Task["monthly_fees:process"].reenable

    allow(Domain::Fees::Repositories::MerchantRepository).to receive(:new).and_return(merchant_repository)
    allow(Domain::Fees::Services::MonthlyFeeTracker).to receive(:new).and_return(monthly_fee_tracker)
    allow(Rails).to receive(:logger).and_return(Logger.new(nil))
  end

  after(:each) do
    Rake::Task["monthly_fees:process"].reenable
    travel_back
  end

  context "when running on first day of month" do
    before do
      travel_to Time.zone.local(2024, 1, 1, 4, 0, 0)
      allow(merchant_repository).to receive(:find_all_merchants_in_batches).and_return([merchant])
      allow(monthly_fee_tracker).to receive(:process_merchant).and_return(true)
    end

    after { travel_back }

    it "processes monthly fees for all merchants" do
      expect(monthly_fee_tracker).to receive(:process_merchant).with(merchant, 12, 2023)
      Rake::Task["monthly_fees:process"].invoke
    end
  end

  context "when not running on first day of month" do
    before do
      travel_to Time.zone.local(2024, 1, 2, 4, 0, 0)
    end

    after { travel_back }

    it "skips processing" do
      expect(merchant_repository).not_to receive(:find_all_merchants_in_batches)
      expect(monthly_fee_tracker).not_to receive(:process_merchant)
      Rake::Task["monthly_fees:process"].invoke
    end
  end
end
