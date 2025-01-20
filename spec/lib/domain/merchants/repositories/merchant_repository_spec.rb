require "rails_helper"

RSpec.describe Domain::Merchants::Repositories::MerchantRepository do
  let(:repository) { described_class.new }
  let(:merchant_attributes) do
    {
      reference: "MERCH123",
      email: "merchant@example.com",
      live_on: Date.new(2024, 3, 20),
      disbursement_frequency: "daily",
      minimum_monthly_fee_cents: 1000
    }
  end

  describe "#create" do
    it "creates a merchant record" do
      expect {
        repository.create(merchant_attributes)
      }.to change(Infrastructure::Persistence::ActiveRecord::Models::Merchant, :count).by(1)
    end

    it "returns a merchant entity" do
      merchant = repository.create(merchant_attributes)
      expect(merchant).to be_a(Domain::Merchants::Entities::Merchant)
    end

    it "sets the correct attributes" do
      merchant = repository.create(merchant_attributes)
      expect(merchant.reference).to eq("MERCH123")
      expect(merchant.email).to eq("merchant@example.com")
      expect(merchant.live_on).to eq(Date.new(2024, 3, 20))
      expect(merchant.disbursement_frequency).to eq("daily")
      expect(merchant.minimum_monthly_fee.cents).to eq(1000)
    end

    context "when validation fails" do
      it "raises RecordInvalid error" do
        expect {
          repository.create(merchant_attributes.merge(email: "invalid-email"))
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "#find" do
    let!(:existing_merchant) { repository.create(merchant_attributes) }

    it "returns a merchant entity" do
      merchant = repository.find(existing_merchant.id)
      expect(merchant).to be_a(Domain::Merchants::Entities::Merchant)
    end

    it "finds the correct merchant" do
      merchant = repository.find(existing_merchant.id)
      expect(merchant.reference).to eq("MERCH123")
      expect(merchant.email).to eq("merchant@example.com")
    end

    context "when merchant doesn't exist" do
      it "raises RecordNotFound error" do
        expect {
          repository.find(SecureRandom.uuid)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
