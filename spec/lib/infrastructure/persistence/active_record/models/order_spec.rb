require "rails_helper"

RSpec.describe Infrastructure::Persistence::ActiveRecord::Models::Order do
  describe "validations" do
    let(:merchant) do
      Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
        reference: "MERCH123",
        email: "merchant@example.com",
        live_on: Date.current,
        disbursement_frequency: "daily",
        minimum_monthly_fee_cents: 1000
      )
    end

    subject(:order) do
      described_class.new(
        id: SecureRandom.hex(6),
        merchant_reference: merchant.reference,
        amount_cents: 10000,
        amount_currency: "EUR",
        created_at: Time.current
      )
    end

    it "is valid with valid attributes" do
      expect(order).to be_valid
    end

    it "requires a merchant_reference" do
      order.merchant_reference = nil
      expect(order).not_to be_valid
      expect(order.errors[:merchant_reference]).to include("can't be blank")
    end

    it "requires an amount" do
      order.amount_cents = nil
      expect(order).not_to be_valid
      expect(order.errors[:amount_cents]).to include("can't be blank")
    end

    it "requires a created_at" do
      order.created_at = nil
      expect(order).not_to be_valid
      expect(order.errors[:created_at]).to include("can't be blank")
    end

    it "validates amount is greater than 0" do
      order.amount_cents = 0
      expect(order).not_to be_valid
      expect(order.errors[:amount_cents]).to include("must be greater than 0")
    end

    it "validates currency is EUR" do
      order.amount_currency = "USD"
      expect(order).not_to be_valid
      expect(order.errors[:amount_currency]).to include("is not included in the list")
    end

    it "validates uniqueness of id" do
      order.save!
      duplicate = described_class.new(order.attributes)

      expect { duplicate.save! }.to raise_error(ActiveRecord::RecordNotUnique)
      expect(duplicate).not_to be_persisted
    end

    it "monetizes amount" do
      order.amount = Money.new(2000, "EUR")
      expect(order.amount_cents).to eq(2000)
      expect(order.amount).to eq(Money.new(2000, "EUR"))
    end

    it "assigns hex ID if id is nil" do
      order.id = nil
      expect { order.valid? }.to change { order.id }.from(nil)
      expect(order.id).to match(/\A[0-9a-f]{12}\z/i)
    end

    it "keeps existing hex ID" do
      existing_id = SecureRandom.hex(6)
      order.id = existing_id
      expect { order.valid? }.not_to change { order.id }
    end

    it "belongs to a merchant" do
      expect(order.merchant).to eq(merchant)
    end
  end
end
