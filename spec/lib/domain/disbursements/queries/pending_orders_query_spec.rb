require "rails_helper"

RSpec.describe Domain::Disbursements::Queries::PendingOrdersQuery do
  let(:query) { described_class.new(date) }
  let(:date) { Date.new(2024, 1, 15) }  # A Tuesday

  # Time helpers - using beginning_of_day to ensure consistent times
  let(:time_today) { date.beginning_of_day.utc }
  let(:time_yesterday) { (date - 1.day).beginning_of_day.utc }
  let(:time_two_days_ago) { (date - 2.days).beginning_of_day.utc }
  let(:time_five_days_ago) { (date - 5.days).beginning_of_day.utc }
  let(:time_eight_days_ago) { (date - 8.days).beginning_of_day.utc }

  describe "#call" do
    let(:merchant) {
      Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
        reference: "REF123",
        email: "merchant@test.com",
        live_on: "2024-01-01",
        disbursement_frequency: disbursement_frequency,
        minimum_monthly_fee_cents: 0
      )
    }

    def create_order(id:, created_at:, pending: true)
      Infrastructure::Persistence::ActiveRecord::Models::Order.create!(
        id: id,
        merchant_reference: merchant.reference,
        amount_cents: 1000,
        created_at: created_at,
        pending_disbursement: pending
      )
    end

    context "with daily disbursement frequency" do
      let(:disbursement_frequency) { "daily" }

      before do
        create_order(
          id: "order1",
          created_at: time_yesterday
        )
        create_order(
          id: "order2",
          created_at: time_two_days_ago
        )
      end

      it "returns orders from previous day as domain entities" do
        result = query.call(merchant)

        expect(result.size).to eq(1)
        expect(result.first).to be_a(Infrastructure::Persistence::ActiveRecord::Models::Order)
        expect(result.first.id).to eq("order1")
        expect(result.first.created_at).to be_within(1.second).of(time_yesterday)
      end

      it "returns empty array when no orders exist" do
        merchant.orders.destroy_all
        expect(query.call(merchant)).to be_empty
      end

      it "returns empty array when all orders are already disbursed" do
        merchant.orders.update_all(pending_disbursement: false)
        expect(query.call(merchant)).to be_empty
      end

      it "returns empty array when all orders are too old" do
        merchant.orders.destroy_all
        create_order(
          id: "old_order",
          created_at: time_two_days_ago
        )
        expect(query.call(merchant)).to be_empty
      end
    end

    context "with weekly disbursement frequency" do
      let(:disbursement_frequency) { "weekly" }

      before do
        create_order(
          id: "order3",
          created_at: time_five_days_ago
        )
        create_order(
          id: "order4",
          created_at: time_eight_days_ago
        )
      end

      it "returns orders from last 7 days as domain entities" do
        result = query.call(merchant)

        expect(result.size).to eq(1)
        expect(result.first).to be_a(Infrastructure::Persistence::ActiveRecord::Models::Order)
        expect(result.first.id).to eq("order3")
        expect(result.first.created_at).to be_within(1.second).of(time_five_days_ago)
      end

      it "returns empty array when no orders exist" do
        merchant.orders.destroy_all
        expect(query.call(merchant)).to be_empty
      end

      it "returns empty array when all orders are already disbursed" do
        merchant.orders.update_all(pending_disbursement: false)
        expect(query.call(merchant)).to be_empty
      end

      it "returns empty array when all orders are too old" do
        merchant.orders.destroy_all
        create_order(
          id: "old_order",
          created_at: time_eight_days_ago
        )
        expect(query.call(merchant)).to be_empty
      end
    end

    context "with edge cases" do
      let(:disbursement_frequency) { "daily" }

      it "handles orders within the daily window" do
        # Create order at start of window (yesterday's beginning)
        order = create_order(
          id: "border_order",
          created_at: time_yesterday # beginning of previous day
        )

        result = query.call(merchant)
        expect(result.map(&:id)).to include(order.id)
      end

      it "excludes orders outside the daily window" do
        # Create order just before window starts (two days ago)
        order = create_order(
          id: "outside_window",
          created_at: time_two_days_ago
        )

        result = query.call(merchant)
        expect(result.map(&:id)).not_to include(order.id)
      end
    end
  end
end
