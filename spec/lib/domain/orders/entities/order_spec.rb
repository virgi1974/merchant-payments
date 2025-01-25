require "rails_helper"

RSpec.describe Domain::Orders::Entities::Order do
  let(:valid_attributes) do
    {
      id: SecureRandom.hex(6),
      merchant_reference: "MERCH123",
      amount_cents: 10050, # 100.50 EUR in cents
      amount_currency: "EUR",
      created_at: Date.new(2024, 3, 20)
    }
  end

  describe ".new" do
    subject(:order) { described_class.new(valid_attributes) }

    it "creates an order with valid attributes" do
      expect(order).to be_a(described_class)
    end

    it "sets the id" do
      expect(order.id).to eq(valid_attributes[:id])
    end

    it "sets the merchant_reference" do
      expect(order.merchant_reference).to eq("MERCH123")
    end

    it "sets the amount" do
      expect(order.amount_cents).to eq(Money.new(10050).cents)
    end

    it "sets the currency" do
      expect(order.amount_currency).to eq("EUR")
    end

    it "sets the created_at date" do
      expect(order.created_at).to eq(Date.new(2024, 3, 20))
    end
  end
end
