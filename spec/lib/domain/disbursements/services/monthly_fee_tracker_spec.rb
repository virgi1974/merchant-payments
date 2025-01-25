require "rails_helper"

RSpec.describe Domain::Disbursements::Services::MonthlyFeeTracker do
  let(:repository) { instance_double(Domain::Disbursements::Repositories::MonthlyFeeRepository) }
  let(:merchant) do
    Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
      reference: "test_merchant",
      email: "test@example.com",
      minimum_monthly_fee_cents: 2900,
      disbursement_frequency: "weekly",
      live_on: Date.current
    )
  end
  let(:month) { 1 }
  let(:year) { 2024 }

  subject(:tracker) { described_class.new(repository) }

  describe "#process_merchant" do
    context "when adjustment already exists" do
      before do
        allow(repository).to receive(:adjustment_exists?).with(merchant, month, year).and_return(true)
      end

      it "does not create new adjustment" do
        expect(repository).not_to receive(:create_monthly_adjustment)
        tracker.process_merchant(merchant, month, year)
      end
    end

    context "when total fees are less than minimum" do
      before do
        allow(repository).to receive(:adjustment_exists?).with(merchant, month, year).and_return(false)
        allow(repository).to receive(:total_fees_for_month).with(merchant, month, year).and_return(1500)
      end

      it "creates adjustment for the difference" do
        expect(repository).to receive(:create_monthly_adjustment).with(
          merchant: merchant,
          amount: 1400,
          month: month,
          year: year
        )
        tracker.process_merchant(merchant, month, year)
      end
    end

    context "when total fees exceed minimum" do
      before do
        allow(repository).to receive(:adjustment_exists?).with(merchant, month, year).and_return(false)
        allow(repository).to receive(:total_fees_for_month).with(merchant, month, year).and_return(3000)
      end

      it "does not create adjustment" do
        expect(repository).not_to receive(:create_monthly_adjustment)
        tracker.process_merchant(merchant, month, year)
      end
    end
  end
end
