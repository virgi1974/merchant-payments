require "rails_helper"

RSpec.describe Domain::Orders::Repositories::OrderRepository do
  let(:repository) { described_class.new }
  let(:merchant) do
    Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
      reference: "MERCH123",
      email: "merchant@example.com",
      live_on: Date.new(2024, 3, 20),
      disbursement_frequency: "daily",
      minimum_monthly_fee_cents: 1000
    )
  end
  let(:order_attributes) do
    {
      merchant_reference: merchant.reference,
      amount_cents: 10050,
      amount_currency: "EUR",
      created_at: Date.new(2024, 3, 20)
    }
  end

  # Create merchant before running tests
  before { merchant }

  describe "#create" do
    it "creates an order record" do
      expect {
        repository.create(order_attributes)
      }.to change(Infrastructure::Persistence::ActiveRecord::Models::Order, :count).by(1)
    end

    it "returns an order entity" do
      order = repository.create(order_attributes)
      expect(order).to be_a(Domain::Orders::Entities::Order)
    end

    it "sets the correct attributes" do
      order = repository.create(order_attributes)
      expect(order.merchant_reference).to eq("MERCH123")
      expect(order.amount_cents).to eq(Money.new(10050))
      expect(order.amount_currency).to eq("EUR")
      expect(order.created_at).to eq(Date.new(2024, 3, 20))
    end

    context "when validation fails" do
      it "raises RecordInvalid error" do
        expect {
          repository.create(order_attributes.merge(amount_cents: nil))
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "raises RecordInvalid error when merchant doesn't exist" do
        expect {
          repository.create(order_attributes.merge(merchant_reference: "NONEXISTENT"))
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "raises RecordInvalid error with invalid currency" do
        expect {
          repository.create(order_attributes.merge(amount_currency: "INVALID"))
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "raises RecordInvalid error with negative amount" do
        expect {
          repository.create(order_attributes.merge(amount_cents: -1000))
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "#find" do
    let!(:existing_order) { repository.create(order_attributes) }

    it "returns an order entity" do
      order = repository.find(existing_order.id)
      expect(order).to be_a(Domain::Orders::Entities::Order)
    end

    it "finds the correct order" do
      order = repository.find(existing_order.id)
      expect(order.merchant_reference).to eq("MERCH123")
      expect(order.amount_cents).to eq(Money.new(10050))
    end

    context "when order doesn't exist" do
      it "raises RecordNotFound error" do
        expect {
          repository.find(SecureRandom.hex(6))
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
