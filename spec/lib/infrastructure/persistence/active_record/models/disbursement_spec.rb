require "rails_helper"

RSpec.describe Infrastructure::Persistence::ActiveRecord::Models::Disbursement do
  describe "validations" do
    let(:merchant) do
      Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
        id: SecureRandom.uuid,
        reference: "MERCH123",
        email: "merchant@example.com",
        live_on: Date.current,
        disbursement_frequency: 0, # 0 for DAILY
        minimum_monthly_fee_cents: 1000
      )
    end

    subject(:disbursement) do
      described_class.new(
        merchant: merchant,
        amount_cents: 10000,
        fees_amount_cents: 100,
        disbursed_at: nil
      )
    end

    it "is valid with valid attributes" do
      expect(disbursement).to be_valid
    end

    it "requires a merchant" do
      disbursement.merchant = nil
      expect(disbursement).not_to be_valid
      expect(disbursement.errors[:merchant]).to include("must exist")
    end

    it "requires amount_cents" do
      disbursement.amount_cents = nil
      expect(disbursement).not_to be_valid
      expect(disbursement.errors[:amount_cents]).to include("can't be blank")
    end

    it "requires fees_amount_cents" do
      disbursement.fees_amount_cents = nil
      expect(disbursement).not_to be_valid
      expect(disbursement.errors[:fees_amount_cents]).to include("can't be blank")
    end

    it "monetizes amount" do
      disbursement.amount = Money.new(2000)
      expect(disbursement.amount_cents).to eq(2000)
      expect(disbursement.amount).to eq(Money.new(2000))
    end

    it "monetizes fees_amount" do
      disbursement.fees_amount = Money.new(100)
      expect(disbursement.fees_amount_cents).to eq(100)
      expect(disbursement.fees_amount).to eq(Money.new(100))
    end

    it "generates a custom id on create" do
      disbursement.save!
      expect(disbursement.id).to match(/^DISB-#{merchant.id}-\d+$/)
    end

    it "validates amount_cents is greater than 0" do
      disbursement.amount_cents = 0
      expect(disbursement).not_to be_valid
      expect(disbursement.errors[:amount_cents]).to include("must be greater than 0")
    end

    it "validates fees_amount_cents is greater than 0" do
      disbursement.fees_amount_cents = 0
      expect(disbursement).not_to be_valid
      expect(disbursement.errors[:fees_amount_cents]).to include("must be greater than 0")
    end
  end

  describe "associations" do
    let(:disbursement) { described_class.new }

    it "belongs to merchant" do
      expect(disbursement).to respond_to(:merchant)
      expect(disbursement).to respond_to(:merchant=)
    end

    it "has many orders" do
      expect(disbursement).to respond_to(:orders)
      expect(disbursement.orders).to be_a(ActiveRecord::Associations::CollectionProxy)
    end
  end
end
