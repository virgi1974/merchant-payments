require "rails_helper"

RSpec.describe Infrastructure::Persistence::ActiveRecord::Models::Disbursement do
  include ActiveSupport::Testing::TimeHelpers

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

  let(:merchant) do
    Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
      reference: "merchant_1",
      email: "merchant@test.com",
      live_on: "2024-01-01",
      disbursement_frequency: "daily",
      minimum_monthly_fee_cents: 0
    )
  end

  describe "scopes" do
    let(:year) { 2024 }

    describe ".for_year" do
      before do
        travel_to Time.zone.local(year, 1, 15, 10, 0, 0) do  # First creation at 10:00
          create_disbursement(1000, 10)
        end

        travel_to Time.zone.local(year + 1, 1, 15, 11, 0, 0) do  # Second creation at 11:00
          create_disbursement(3000, 30)
        end
      end

      it "returns disbursements for the specified year" do
        expect(described_class.for_year(2024).count).to eq(1)
        expect(described_class.for_year(2024).pluck(:created_at).map(&:year)).to eq([ 2024 ])
        expect(described_class.for_year(2025).count).to eq(1)
        expect(described_class.for_year(2025).pluck(:created_at).map(&:year)).to eq([ 2025 ])
      end
    end

    describe ".sum_amount_for_year" do
      before do
        travel_to Time.zone.local(year, 1, 15, 10, 0, 0) do  # First creation at 10:00
          create_disbursement(1000, 10)
        end

        travel_to Time.zone.local(year, 1, 15, 11, 0, 0) do  # Second creation at 11:00
          create_disbursement(2000, 20)
        end
      end

      it "returns the sum of amounts for the specified year" do
        expect(described_class.sum_amount_for_year(2024)).to eq(3000)
      end
    end

    describe ".sum_fees_for_year" do
      before do
        travel_to Time.zone.local(year, 1, 15, 10, 0, 0) do  # First creation at 10:00
          create_disbursement(1000, 10)
        end

        travel_to Time.zone.local(year, 1, 15, 11, 0, 0) do  # Second creation at 11:00
          create_disbursement(2000, 20)
        end
      end

      it "returns the sum of fees for the specified year" do
        expect(described_class.sum_fees_for_year(2024)).to eq(30)
      end
    end
  end

  private

  def create_disbursement(amount, fees)
    sleep 1
    described_class.create!(
      id: "DISB-#{merchant.id}-#{Time.current.to_i}-#{SecureRandom.hex(4)}",
      merchant: merchant,
      amount_cents: amount,
      fees_amount_cents: fees,
      disbursed_at: Time.current
    )
  end
end
