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
      let(:month) { 1 }
      let(:year) { 2024 }

      before do
        create_adjustment(1000, month, year)
        create_adjustment(2000, month + 1, year)
        create_adjustment(3000, month, year + 1)
      end

      it "returns adjustments for the specified month and year" do
        result = described_class.for_month_and_year(month, year)
        expect(result.count).to eq(1)
        expect(result.first.amount_cents).to eq(1000)
      end
    end

    describe ".for_year" do
      let(:year) { 2024 }

      before do
        create_adjustment(1000, 1, year)
        create_adjustment(2000, 2, year)
        create_adjustment(3000, 1, year + 1)
      end

      it "returns adjustments for the specified year" do
        expect(described_class.for_year(year).count).to eq(2)
      end
    end

    describe ".total_amount_for_year" do
      let(:year) { 2024 }

      before do
        create_adjustment(1000, 1, year)
        create_adjustment(2000, 2, year)
        create_adjustment(3000, 1, year + 1)
      end

      it "returns the sum of amounts for the specified year" do
        expect(described_class.total_amount_for_year(year)).to eq(3000)
      end

      it "returns zero when no adjustments exist" do
        expect(described_class.total_amount_for_year(2020)).to eq(0)
      end
    end

    describe ".count_for_year" do
      let(:year) { 2024 }

      before do
        create_adjustment(1000, 1, year)
        create_adjustment(2000, 2, year)
        create_adjustment(3000, 1, year + 1)
      end

      it "returns the count of adjustments for the specified year" do
        expect(described_class.count_for_year(year)).to eq(2)
      end

      it "returns zero when no adjustments exist" do
        expect(described_class.count_for_year(2020)).to eq(0)
      end
    end
  end

  private

  def create_adjustment(amount, month, year)
    described_class.create!(
      merchant: merchant,
      amount_cents: amount,
      month: month,
      year: year
    )
  end
end
