require "rails_helper"

RSpec.describe Domain::Orders::Services::OrderCreators::BaseCreator do
  let(:test_creator) { Class.new(described_class) }
  let(:merchant) do
    Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
      reference: "MERCH123",
      email: "merchant@example.com",
      live_on: Date.current,
      disbursement_frequency: "daily",
      minimum_monthly_fee_cents: 1000
    )
  end

  shared_examples "base creator behavior" do
    describe ".call" do
      context "when called on BaseCreator directly" do
        it "raises NotImplementedError" do
          expect {
            described_class.call(order_data)
          }.to raise_error(NotImplementedError, /is an abstract class/)
        end
      end
    end

    describe "#initialize" do
      context "when instantiating BaseCreator directly" do
        it "raises NotImplementedError" do
          expect {
            described_class.new(order_data)
          }.to raise_error(NotImplementedError, /is an abstract class/)
        end
      end
    end

    describe "#call" do
      it "validates and creates order" do
        creator = test_creator.new(order_data)
        expect(creator).to receive(:validate_order_data)
        expect(creator).to receive(:normalize_order_data)
        expect(creator).to receive(:create_order)
        creator.call
      end
    end

    describe "validations" do
      context "when amount is negative" do
        before do
          allow(order_data)
            .to receive(:amount)
            .and_return(BigDecimal("-100.50"))
        end

        it "raises InvalidMinimumAmount" do
          expect {
            test_creator.call(order_data)
          }.to raise_error(Domain::Orders::Errors::InvalidMinimumAmount)
        end
      end
    end

    describe "error handling" do
      context "when database operation fails" do
        before do
          allow_any_instance_of(Domain::Orders::Repositories::OrderRepository)
            .to receive(:create)
            .and_raise(StandardError, "Database connection lost")
        end

        it "propagates the error" do
          expect {
            test_creator.call(order_data)
          }.to raise_error(StandardError, "Database connection lost")
        end
      end
    end
  end

  context "when used for CSV import" do
    let(:order_data) do
      instance_double(
        "OrderData",
        id: SecureRandom.hex(6),
        merchant_reference: "MERCH123",
        amount: BigDecimal("100.50"),
        created_at: Date.new(2024, 3, 20)
      )
    end

    before { merchant }

    include_examples "base creator behavior"

    describe "data normalization" do
      let(:normalized_data) do
        {
          id: order_data.id,
          merchant_reference: order_data.merchant_reference,
          amount_cents: Money.from_amount(100.50).cents,
          amount_currency: "EUR",
          created_at: order_data.created_at
        }
      end

      it "normalizes order data correctly with ID" do
        creator = test_creator.new(order_data)
        allow(creator).to receive(:create_order)
        expect(creator).to receive(:create_order).with(normalized_data)
        creator.call
      end
    end
  end

  context "when used for API import" do
    let(:order_data) do
      instance_double(
        "OrderData",
        id: nil,
        merchant_reference: "MERCH123",
        amount: BigDecimal("100.50"),
        created_at: Date.new(2024, 3, 20)
      )
    end

    before { merchant }

    include_examples "base creator behavior"

    describe "data normalization" do
      let(:normalized_data) do
        {
          id: nil,
          merchant_reference: order_data.merchant_reference,
          amount_cents: Money.from_amount(100.50).cents,
          amount_currency: "EUR",
          created_at: order_data.created_at
        }
      end

      it "normalizes order data correctly without ID" do
        creator = test_creator.new(order_data)
        allow(creator).to receive(:create_order)
        expect(creator).to receive(:create_order).with(normalized_data)
        creator.call
      end
    end
  end
end
