require "rails_helper"

RSpec.describe Domain::Disbursements::Services::Calculators::Weekly do
  let(:reference_date) { Date.new(2024, 1, 15) } # Tuesday
  let(:merchant) do
    instance_double(Domain::Merchants::Entities::DisbursableMerchant,
      id: 1,
      reference: "weekly_merchant",
      disbursement_frequency: "weekly",
      live_on: Date.new(2024, 1, 10), # Wednesday
      minimum_monthly_fee_cents: 2900)
  end
  let(:repository) { instance_double(Domain::Disbursements::Repositories::DisbursementRepository) }
  let(:orders_query) { instance_double(Domain::Disbursements::Queries::PendingOrdersQuery) }

  let(:order1) do
    instance_double(Infrastructure::Persistence::ActiveRecord::Models::Order,
      id: 1,
      amount_cents: 5000,
      created_at: reference_date)
  end

  let(:order2) do
    instance_double(Infrastructure::Persistence::ActiveRecord::Models::Order,
      id: 2,
      amount_cents: 3000,
      created_at: reference_date)
  end

  subject(:calculator) { described_class.new(merchant, reference_date, repository) }

  before do
    allow(Domain::Disbursements::Queries::PendingOrdersQuery).to receive(:new)
      .with(reference_date)
      .and_return(orders_query)
  end

  describe "#calculate_and_create" do
    context "when processing on merchant's live day of week" do
      let(:reference_date) { Date.new(2024, 1, 17) } # Wednesday

      before do
        allow(orders_query).to receive(:call).with(merchant).and_return([ order1, order2 ])
        allow(repository).to receive(:create).and_return(
          instance_double(Domain::Disbursements::Entities::Disbursement,
            merchant_id: merchant.id,
            orders: [ order1, order2 ])
        )
      end

      it "creates a disbursement with the correct data" do
        expect(repository).to receive(:create).with(
          hash_including(
            merchant_id: merchant.id,
            amount_cents: 8000, # 5000 + 3000
            orders: [ order1, order2 ],
            fees_amount_cents: 78 # 0.95% fee for amount >= 50€
          )
        )

        calculator.calculate_and_create
      end

      context "when no orders exist" do
        before do
          allow(orders_query).to receive(:call).with(merchant).and_return([])
        end

        it "returns nil" do
          expect(calculator.calculate_and_create).to be_nil
        end
      end

      context "when repository fails" do
        before do
          allow(repository).to receive(:create).and_raise(StandardError.new("DB Error"))
        end

        it "raises the error" do
          expect { calculator.calculate_and_create }.to raise_error(StandardError, "DB Error")
        end
      end

      context "with different fee tiers" do
        let(:small_order) do
          instance_double(Infrastructure::Persistence::ActiveRecord::Models::Order,
            id: 3,
            amount_cents: 4000, # 40€, 1% fee tier
            created_at: reference_date)
        end

        let(:large_order) do
          instance_double(Infrastructure::Persistence::ActiveRecord::Models::Order,
            id: 4,
            amount_cents: 35000, # 350€, 0.85% fee tier
            created_at: reference_date)
        end

        it "calculates correct fees for small amounts" do
          allow(orders_query).to receive(:call).with(merchant).and_return([ small_order ])
          expect(repository).to receive(:create).with(
            hash_including(
              amount_cents: 4000,
              fees_amount_cents: 40 # 1% of 4000
            )
          )
          calculator.calculate_and_create
        end

        it "calculates correct fees for large amounts" do
          allow(orders_query).to receive(:call).with(merchant).and_return([ large_order ])
          expect(repository).to receive(:create).with(
            hash_including(
              amount_cents: 35000,
              fees_amount_cents: 298 # 0.85% of 35000
            )
          )
          calculator.calculate_and_create
        end
      end
    end

    context "when processing on different day of week" do
      let(:reference_date) { Date.new(2024, 1, 16) } # Tuesday

      before do
        allow(orders_query).to receive(:call).with(merchant).and_return([ order1, order2 ])
      end

      it "returns nil without creating disbursement" do
        expect(repository).not_to receive(:create)
        expect(calculator.calculate_and_create).to be_nil
      end

      it "doesn't query for orders" do
        expect(orders_query).not_to receive(:call)
        calculator.calculate_and_create
      end
    end
  end

  describe "#fetch_orders" do
    context "when processing on merchant's live day (Wednesday)" do
      let(:merchant) do
        instance_double(Domain::Merchants::Entities::DisbursableMerchant,
          id: 1,
          reference: "weekly_merchant",
          disbursement_frequency: "weekly",
          live_on: Date.new(2024, 1, 17), # Wednesday
          minimum_monthly_fee_cents: 2900)
      end

      let(:reference_date) { Date.new(2024, 1, 24) } # Next Wednesday

      it "calls the orders query" do
        expect(orders_query).to receive(:call).with(merchant)
        calculator.send(:fetch_orders)
      end
    end

    context "when processing on different days" do
      let(:merchant) do
        instance_double(Domain::Merchants::Entities::DisbursableMerchant,
          id: 1,
          reference: "weekly_merchant",
          disbursement_frequency: "weekly",
          live_on: Date.new(2024, 1, 17), # Wednesday
          minimum_monthly_fee_cents: 2900)
      end

      [
        Date.new(2024, 1, 15), # Monday
        Date.new(2024, 1, 16), # Tuesday
        Date.new(2024, 1, 18), # Thursday
        Date.new(2024, 1, 19), # Friday
        Date.new(2024, 1, 20), # Saturday
        Date.new(2024, 1, 21)  # Sunday
      ].each do |test_date|
        context "when processing on #{test_date.strftime("%A")}" do
          let(:reference_date) { test_date }

          it "returns empty array without calling query" do
            expect(orders_query).not_to receive(:call)
            expect(calculator.send(:fetch_orders)).to eq([])
          end
        end
      end
    end
  end
end
