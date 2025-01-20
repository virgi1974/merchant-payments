require "rails_helper"

RSpec.describe Infrastructure::Persistence::ActiveRecord::Models::Merchant do
  describe "validations" do
    subject(:merchant) do
      described_class.new(
        id: SecureRandom.uuid,
        reference: "MERCH123",
        email: "merchant@example.com",
        live_on: Date.current,
        disbursement_frequency: 0, # 0 for DAILY
        minimum_monthly_fee_cents: 1000
      )
    end

    it "is valid with valid attributes" do
      expect(merchant).to be_valid
    end

    it "requires a reference" do
      merchant.reference = nil
      expect(merchant).not_to be_valid
      expect(merchant.errors[:reference]).to include("can't be blank")
    end

    it "requires an email" do
      merchant.email = nil
      expect(merchant).not_to be_valid
      expect(merchant.errors[:email]).to include("can't be blank")
    end

    it "requires a live_on date" do
      merchant.live_on = nil
      expect(merchant).not_to be_valid
      expect(merchant.errors[:live_on]).to include("can't be blank")
    end

    it "requires a disbursement_frequency" do
      merchant.disbursement_frequency = nil
      expect(merchant).not_to be_valid
      expect(merchant.errors[:disbursement_frequency]).to include("can't be blank")
    end

    it "requires a minimum_monthly_fee" do
      merchant.minimum_monthly_fee_cents = nil
      expect(merchant).not_to be_valid
      expect(merchant.errors[:minimum_monthly_fee_cents]).to include("can't be blank")
    end

    it "validates uniqueness of id and reference" do
      merchant.save!
      duplicate = described_class.new(merchant.attributes)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:id]).to include("has already been taken")
      expect(duplicate.errors[:reference]).to include("has already been taken")
    end

    it "validates email format" do
      merchant.email = "invalid-email"
      expect(merchant).not_to be_valid
      expect(merchant.errors[:email]).to include("is invalid")
    end

    it "validates minimum_monthly_fee is not negative" do
      merchant.minimum_monthly_fee_cents = -100
      expect(merchant).not_to be_valid
      expect(merchant.errors[:minimum_monthly_fee_cents]).to include("must be greater than or equal to 0")
    end

    it "validates disbursement_frequency values" do
      Domain::Merchants::ValueObjects::DisbursementFrequency.values.each do |frequency|
        merchant.disbursement_frequency = frequency.downcase
        expect(merchant).to be_valid
      end

      expect {
        merchant.disbursement_frequency = "invalid"
      }.to raise_error(ArgumentError, "'invalid' is not a valid disbursement_frequency")
    end

    it "monetizes minimum_monthly_fee" do
      merchant.minimum_monthly_fee = Money.new(2000)
      expect(merchant.minimum_monthly_fee_cents).to eq(2000)
      expect(merchant.minimum_monthly_fee).to eq(Money.new(2000))
    end

    it "assigns UUID if id is nil" do
      merchant.id = nil
      expect { merchant.valid? }.to change { merchant.id }.from(nil)
      expect(merchant.id).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
    end

    it "keeps existing UUID" do
      existing_uuid = SecureRandom.uuid
      merchant.id = existing_uuid
      expect { merchant.valid? }.not_to change { merchant.id }
    end
  end
end
