require "rails_helper"

RSpec.describe Domain::Disbursements::Services::Calculators::Daily do
  let(:reference_date) { Date.new(2024, 1, 15) }
  let(:merchant) do
    instance_double(Domain::Merchants::Entities::DisbursableMerchant,
      id: 1,
      reference: "daily_merchant",
      disbursement_frequency: "daily",
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
          fees_amount_cents: 78 # Calculated fee for 8000 cents
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
  end
end
