require "rails_helper"

RSpec.describe Infrastructure::Persistence::ActiveRecord::Models::MonthlyFeeAdjustment do
  let(:merchant) do
    Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
      reference: "test_merchant",
      email: "test@example.com",
      minimum_monthly_fee_cents: 2900,
      disbursement_frequency: "weekly",
      live_on: Date.current
    )
  end

  describe "validations" do
    subject(:adjustment) do
      described_class.new(
        merchant: merchant,
        amount_cents: 1000,
        month: 1,
        year: 2024
      )
    end

    it { is_expected.to be_valid }

    context "when amount_cents is missing" do
      before { adjustment.amount_cents = nil }
      it { is_expected.not_to be_valid }
    end

    context "when amount_cents is negative" do
      before { adjustment.amount_cents = -1 }
      it { is_expected.not_to be_valid }
    end

    context "when month is missing" do
      before { adjustment.month = nil }
      it { is_expected.not_to be_valid }
    end

    context "when month is invalid" do
      before { adjustment.month = 13 }
      it { is_expected.not_to be_valid }
    end

    context "when year is missing" do
      before { adjustment.year = nil }
      it { is_expected.not_to be_valid }
    end

    context "when merchant is missing" do
      before { adjustment.merchant = nil }
      it { is_expected.not_to be_valid }
    end

    context "when duplicate adjustment exists for same merchant/month/year" do
      before do
        described_class.create!(
          merchant: merchant,
          amount_cents: 500,
          month: adjustment.month,
          year: adjustment.year
        )
      end

      it { is_expected.not_to be_valid }
    end
  end

  describe "associations" do
    it "belongs to merchant" do
      adjustment = described_class.create!(
        merchant: merchant,
        amount_cents: 1000,
        month: 1,
        year: 2024
      )

      expect(adjustment.merchant).to eq(merchant)
    end
  end

  describe "scopes" do
    describe ".for_month_and_year" do
      let!(:adjustment_january_2024) do
        described_class.create!(
          merchant: merchant,
          amount_cents: 1000,
          month: 1,
          year: 2024
        )
      end

      let!(:adjustment_february_2024) do
        described_class.create!(
          merchant: merchant,
          amount_cents: 1500,
          month: 2,
          year: 2024
        )
      end

      let!(:adjustment_january_2023) do
        described_class.create!(
          merchant: merchant,
          amount_cents: 2000,
          month: 1,
          year: 2023
        )
      end

      it "returns adjustments for the specified month and year" do
        result = described_class.for_month_and_year(1, 2024)

        expect(result).to include(adjustment_january_2024)
        expect(result).not_to include(adjustment_february_2024)
        expect(result).not_to include(adjustment_january_2023)
      end
    end
  end
end
