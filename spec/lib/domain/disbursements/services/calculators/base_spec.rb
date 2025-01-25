require "rails_helper"

RSpec.describe Domain::Disbursements::Services::Calculators::Base do
  # Concrete implementation for testing
  class TestCalculator < described_class
    protected

    def fetch_orders
      @orders_query.call(@merchant)
    end
  end

  let(:reference_date) { Date.new(2024, 1, 15) }
  let(:merchant) do
    instance_double(Domain::Merchants::Entities::DisbursableMerchant,
      id: 1,
      reference: "test_merchant",
      minimum_monthly_fee_cents: 2900)
  end
  let(:repository) { instance_double(Domain::Disbursements::Repositories::DisbursementRepository) }
  let(:orders_query) { instance_double(Domain::Disbursements::Queries::PendingOrdersQuery) }
  let(:fee_calculator) { instance_double(Domain::Disbursements::Services::FeeCalculator) }

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

  subject(:calculator) { TestCalculator.new(merchant, reference_date, repository) }

  before do
    allow(Domain::Disbursements::Services::FeeCalculator).to receive(:new).and_return(fee_calculator)
    allow(Domain::Disbursements::Queries::PendingOrdersQuery).to receive(:new)
      .with(reference_date)
      .and_return(orders_query)
  end

  describe "#calculate_and_create" do
    before do
      allow(orders_query).to receive(:call).with(merchant).and_return([ order1, order2 ])
      allow(fee_calculator).to receive(:calculate_total_fees).with([ order1, order2 ]).and_return(78)
      allow(repository).to receive(:create).and_return(
        instance_double(Domain::Disbursements::Entities::Disbursement,
          merchant_id: merchant.id,
          orders: [ order1, order2 ])
      )
    end

    it "creates a disbursement with the correct attributes" do
      expect(repository).to receive(:create).with(
        hash_including(
          merchant_id: merchant.id,
          amount_cents: 8000,
          fees_amount_cents: 78,
          orders: [ order1, order2 ],
          disbursed_at: instance_of(Time)
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

    context "when validation fails" do
      let(:validator) { instance_double(Domain::Disbursements::Data::Validator, valid?: false) }
      let(:error_messages) { [ "Amount must be positive" ] }

      before do
        allow(Domain::Disbursements::Data::Validator).to receive(:new)
          .and_return(validator)
        allow(validator).to receive(:errors)
          .and_return(double(full_messages: error_messages))
      end

      xit "returns nil and logs error" do
        expect(Rails.logger).to receive(:error)
          .with("Validation failed for merchant 1: Amount must be positive")
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

  describe "#fetch_orders" do
    it "raises NotImplementedError when called on Base" do
      base_calculator = described_class.new(merchant, reference_date, repository)
      expect { base_calculator.send(:fetch_orders) }
        .to raise_error(NotImplementedError, "Domain::Disbursements::Services::Calculators::Base must implement #fetch_orders")
    end
  end
end
