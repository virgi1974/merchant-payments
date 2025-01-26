require "rails_helper"

RSpec.describe "Daily Disbursements Integration" do
  let(:repository) { Domain::Disbursements::Repositories::DisbursementRepository.new }
  let(:reference_date) { Date.current }
  let(:merchant) do
    Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
      reference: "daily_merchant",
      disbursement_frequency: "daily",
      live_on: reference_date - 1.day,  # Live before orders
      email: "daily@example.com",
      minimum_monthly_fee_cents: 2900
    )
  end

  let!(:yesterdays_order) do
    Infrastructure::Persistence::ActiveRecord::Models::Order.create!(
      merchant_reference: merchant.reference,
      amount_cents: 5000,
      created_at: reference_date - 1.day  # Yesterday's order
    )
  end

  let!(:todays_order) do
    Infrastructure::Persistence::ActiveRecord::Models::Order.create!(
      merchant_reference: merchant.reference,
      amount_cents: 6000,
      created_at: reference_date
    )
  end

  it "creates disbursements only with yesterday's orders" do
    calculator = Domain::Disbursements::Services::Calculators::Daily.new(
      merchant, reference_date, repository
    )

    result = calculator.calculate_and_create

    expect(result).to be_a(Domain::Disbursements::Entities::Disbursement)
    expect(result.merchant_id).to eq(merchant.id)
    expect(result.orders).to include(yesterdays_order)
    expect(result.orders).not_to include(todays_order)
    expect(result.amount_cents).to eq(5000)
    expect(result.fees_amount_cents).to eq(48) # 0.95% fee for amount >= 50€
  end
end
