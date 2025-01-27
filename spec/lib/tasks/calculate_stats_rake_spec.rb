require "rails_helper"
require "rake"

RSpec.describe "stats:calculate_table_data" do
  include ActiveSupport::Testing::TimeHelpers

  before do
    Rails.application.load_tasks
    Rake::Task.define_task(:environment)
    # Mock the historical task to prevent it from running
    allow(Rake::Task["monthly_fees:process_historical"]).to receive(:invoke)
  end

  let(:merchant) do
    Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
      reference: "merchant_1",
      email: "merchant@test.com",
      live_on: "2024-01-01",
      disbursement_frequency: "daily",
      minimum_monthly_fee_cents: 2900
    )
  end

  it "calculates and prints statistics for 2022-2023" do
    travel_to Time.zone.local(2022, 1, 15) do
      create_disbursement(1000, 10)
      create_monthly_fee(2900)
    end

    travel_to Time.zone.local(2023, 1, 15) do
      create_disbursement(2000, 20)
      create_monthly_fee(2900)
    end

    expected_output = <<~TABLE
      | Year | Number of disbursements | Amount disbursed to merchants | Amount of order fees | Number of monthly fees charged | Amount of monthly fee charged |
      |------|------------------------|----------------------------|--------------------|-----------------------------|----------------------------|
      | 2022 | 1 | 10.0 € | 0.1 € | 1 | 29.0 € |
      | 2023 | 1 | 20.0 € | 0.2 € | 1 | 29.0 € |
    TABLE

    expect { Rake::Task["stats:calculate_table_data"].execute }.to output(expected_output).to_stdout
  end

  private

  def create_disbursement(amount, fees)
    Infrastructure::Persistence::ActiveRecord::Models::Disbursement.create!(
      id: "DISB-#{merchant.id}-#{SecureRandom.hex(8)}",
      merchant: merchant,
      amount_cents: amount,
      fees_amount_cents: fees,
      disbursed_at: Time.current
    )
  end

  def create_monthly_fee(amount)
    Infrastructure::Persistence::ActiveRecord::Models::MonthlyFeeAdjustment.create!(
      merchant: merchant,
      amount_cents: amount,
      month: Time.current.month,
      year: Time.current.year
    )
  end
end
