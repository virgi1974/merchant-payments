require "rails_helper"

RSpec.describe "Weekly Disbursements Integration" do
  let(:repository) { Domain::Disbursements::Repositories::DisbursementRepository.new }
  let(:reference_date) { Date.new(2024, 1, 17) } # Wednesday

  let(:merchant) do
    Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
      reference: "weekly_merchant",
      disbursement_frequency: "weekly",
      live_on: reference_date,
      email: "weekly@example.com",
      minimum_monthly_fee_cents: 2900
    )
  end

  let!(:order) do
    Infrastructure::Persistence::ActiveRecord::Models::Order.create!(
      merchant_reference: merchant.reference,
      amount_cents: 5000,
      created_at: reference_date,  # Match the reference_date
      pending_disbursement: true
    )
  end

  context "when processing on merchant's live day" do
    it "creates disbursements with real components" do
      calculator = Domain::Disbursements::Services::Calculators::Weekly.new(
        merchant, reference_date, repository
      )

      result = calculator.calculate_and_create

      expect(result).to be_a(Domain::Disbursements::Entities::Disbursement)
      expect(result.merchant_id).to eq(merchant.id)
      expect(result.orders).to include(order)
      expect(result.amount_cents).to eq(5000)
      expect(result.fees_amount_cents).to eq(48) # 0.95% fee for amount >= 50€
    end
  end

  context "when processing on different day" do
    let(:different_date) { Date.new(2024, 1, 16) } # Tuesday
    let!(:another_order) do
      Infrastructure::Persistence::ActiveRecord::Models::Order.create!(
        merchant_reference: merchant.reference,
        amount_cents: 6000,
        created_at: different_date,
        pending_disbursement: true
      )
    end

    it "does not create disbursement even with pending orders" do
      calculator = Domain::Disbursements::Services::Calculators::Weekly.new(
        merchant, different_date, repository
      )

      result = calculator.calculate_and_create

      expect(result).to be_nil
      # Verify order remains pending
      expect(another_order.reload.pending_disbursement).to be true
    end
  end
end
