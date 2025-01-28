require "rails_helper"
require "rake"

RSpec.describe "monthly_fees:process rake task" do
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
    Rails.application.load_tasks
    Rake::Task.define_task(:environment)
    allow(Domain::Fees::Repositories::MerchantRepository).to receive(:new).and_return(merchant_repository)
    allow(Domain::Fees::Services::MonthlyFeeTracker).to receive(:new).and_return(monthly_fee_tracker)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  context "when running on first day of month" do
    before do
      travel_to Time.zone.local(2024, 1, 1, 4, 0, 0)
    end

    after { travel_back }

    it "processes monthly fees for all merchants" do
      allow(merchant_repository).to receive(:find_all_merchants_in_batches).and_return([ merchant ])
      allow(monthly_fee_tracker).to receive(:process_merchant).and_return(true)

      expect(monthly_fee_tracker).to receive(:process_merchant).with(merchant, 12, 2023)
      expect { Rake::Task["monthly_fees:process"].execute }.not_to raise_error
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
      expect { Rake::Task["monthly_fees:process"].execute }.not_to raise_error
    end
  end
end
