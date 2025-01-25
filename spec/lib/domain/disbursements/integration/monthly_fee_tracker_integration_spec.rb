require "rails_helper"

RSpec.describe Domain::Disbursements::Services::MonthlyFeeTracker, type: :integration do
  let(:repository) { Domain::Disbursements::Repositories::MonthlyFeeRepository.new }
  let(:merchant) do
    Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
      reference: "test_merchant",
      email: "test@example.com",
      minimum_monthly_fee_cents: 2900,
      disbursement_frequency: "weekly",
      live_on: Date.current
    )
  end

  let(:month) { Date.current.month }
  let(:year) { Date.current.year }

  subject(:tracker) { described_class.new(repository) }

  context "with real database interactions" do
    before do
      Timecop.freeze(Time.current) do
        Infrastructure::Persistence::ActiveRecord::Models::Disbursement.create!(
          merchant_id: merchant.id,
          amount_cents: 10000,
          fees_amount_cents: 1000,
          disbursed_at: Date.new(year, month, 15)
        )
      end

      Timecop.freeze(1.second.from_now) do
        Infrastructure::Persistence::ActiveRecord::Models::Disbursement.create!(
          merchant_id: merchant.id,
          amount_cents: 5000,
          fees_amount_cents: 500,
          disbursed_at: Date.new(year, month, 20)
        )
      end
    end

    it "creates adjustment when fees are below minimum" do
      expect {
        tracker.process_merchant(merchant, month, year)
      }.to change(Infrastructure::Persistence::ActiveRecord::Models::MonthlyFeeAdjustment, :count).by(1)

      adjustment = merchant.monthly_fee_adjustments.last
      expect(adjustment.amount_cents).to eq(1400) # 2900 - (1000 + 500)
      expect(adjustment.month).to eq(month)
      expect(adjustment.year).to eq(year)
    end

    it "prevents duplicate adjustments" do
      tracker.process_merchant(merchant, month, year)

      expect {
        tracker.process_merchant(merchant, month, year)
      }.not_to change(Infrastructure::Persistence::ActiveRecord::Models::MonthlyFeeAdjustment, :count)
    end
  end
end
