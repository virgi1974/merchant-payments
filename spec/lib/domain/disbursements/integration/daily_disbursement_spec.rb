require "rails_helper"

RSpec.describe "Daily Disbursements Integration" do
  let(:repository) { Domain::Disbursements::Repositories::DisbursementRepository.new }
  let(:merchant) do
    Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
      reference: "daily_merchant",
      disbursement_frequency: "daily",
      live_on: Date.current,
      email: "daily@example.com",
      minimum_monthly_fee_cents: 2900
    )
  end

  let!(:order) do
    Infrastructure::Persistence::ActiveRecord::Models::Order.create!(
      merchant_reference: merchant.reference,
      amount_cents: 5000,
      created_at: Date.current
    )
  end

  it "creates disbursements with real components" do
    calculator = Domain::Disbursements::Services::Calculators::Daily.new(
      merchant, Date.current, repository
    )

    result = calculator.calculate_and_create

    expect(result).to be_a(Domain::Disbursements::Entities::Disbursement)
    expect(result.merchant_id).to eq(merchant.id)
    expect(result.orders).to include(order)
    expect(result.amount_cents).to eq(5000)
    expect(result.fees_amount_cents).to eq(48) # 0.95% fee for amount >= 50€
  end
end
