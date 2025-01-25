require "rails_helper"

RSpec.describe Domain::Disbursements::Repositories::MonthlyFeeRepository do
  let(:merchant) do
    Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
      reference: "test_merchant",
      email: "test@example.com",
      minimum_monthly_fee_cents: 2900,
      disbursement_frequency: "weekly",
      live_on: Date.current
    )
  end

  subject(:repository) { described_class.new }

  describe "#total_fees_for_month" do
    let(:month) { Date.current.month }
    let(:year) { Date.current.year }

    context "when disbursements exist" do
      before do
        Timecop.freeze(Time.zone.local(year, month, 15)) do
          Infrastructure::Persistence::ActiveRecord::Models::Disbursement.create!(
            merchant_id: merchant.id,
            amount_cents: 10000,
            fees_amount_cents: 1000,
            disbursed_at: Time.current
          )
        end

        Timecop.freeze(Time.zone.local(year, month, 20)) do
          Infrastructure::Persistence::ActiveRecord::Models::Disbursement.create!(
            merchant_id: merchant.id,
            amount_cents: 5000,
            fees_amount_cents: 500,
            disbursed_at: Time.current
          )
        end

        Timecop.freeze(Time.zone.local(year, month + 1, 1)) do
          Infrastructure::Persistence::ActiveRecord::Models::Disbursement.create!(
            merchant_id: merchant.id,
            amount_cents: 3000,
            fees_amount_cents: 300,
            disbursed_at: Time.current
          )
        end
      end

      it "returns total fees for the specified month" do
        total = repository.total_fees_for_month(merchant, month, year)
        expect(total).to eq(1500) # 1000 + 500
      end
    end

    context "when no disbursements exist" do
      it "returns zero" do
        total = repository.total_fees_for_month(merchant, month, year)
        expect(total).to eq(0)
      end
    end
  end

  describe "#create_monthly_adjustment" do
    it "creates a monthly fee adjustment" do
      expect {
        repository.create_monthly_adjustment(
          merchant: merchant,
          amount: 1400,
          month: 1,
          year: 2024
        )
      }.to change(Infrastructure::Persistence::ActiveRecord::Models::MonthlyFeeAdjustment, :count).by(1)

      adjustment = merchant.monthly_fee_adjustments.last
      expect(adjustment.amount_cents).to eq(1400)
      expect(adjustment.month).to eq(1)
      expect(adjustment.year).to eq(2024)
    end
  end

  describe "#adjustment_exists?" do
    let(:month) { 1 }
    let(:year) { 2024 }

    context "when adjustment exists" do
      before do
        Infrastructure::Persistence::ActiveRecord::Models::MonthlyFeeAdjustment.create!(
          merchant: merchant,
          amount_cents: 1400,
          month: month,
          year: year
        )
      end

      it "returns true" do
        expect(repository.adjustment_exists?(merchant, month, year)).to be true
      end
    end

    context "when adjustment does not exist" do
      it "returns false" do
        expect(repository.adjustment_exists?(merchant, month, year)).to be false
      end
    end
  end
end
