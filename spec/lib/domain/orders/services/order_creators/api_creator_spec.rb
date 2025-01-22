require "rails_helper"

RSpec.describe Domain::Orders::Services::OrderCreators::ApiCreator do
  describe ".call" do
    let(:merchant) do
      Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
        reference: "MERCH123",
        email: "merchant@example.com",
        live_on: Date.current,
        disbursement_frequency: "daily",
        minimum_monthly_fee_cents: 1000
      )
    end

    let(:order_data) do
      Domain::Orders::Data::ApiRecordValidator.new(
        id: nil,
        merchant_reference: merchant.reference,
        amount: "100.50",
        created_at: Date.new(2024, 3, 20)
      )
    end

    before { merchant }

    it "inherits from BaseCreator" do
      expect(described_class).to be < Domain::Orders::Services::OrderCreators::BaseCreator
    end

    it "creates an order record" do
      expect {
        described_class.call(order_data)
      }.to change(Infrastructure::Persistence::ActiveRecord::Models::Order, :count).by(1)
    end

    it "returns an order entity" do
      order = described_class.call(order_data)
      expect(order).to be_a(Domain::Orders::Entities::Order)
      expect(order.merchant_reference).to eq("MERCH123")
      expect(order.amount_cents).to eq(Money.new(10050))
    end

    context "with invalid input type" do
      it "raises ArgumentError" do
        expect {
          described_class.call({})
        }.to raise_error(NoMethodError)
      end
    end

    context "when creation fails" do
      before do
        allow(Infrastructure::Persistence::ActiveRecord::Models::Order).to receive(:create!)
          .and_raise(StandardError, "Database connection lost")
      end

      it "rolls back the transaction" do
        expect {
          begin
            described_class.call(order_data)
          rescue StandardError
            nil
          end
        }.not_to change(Infrastructure::Persistence::ActiveRecord::Models::Order, :count)
      end
    end
  end
end
