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

  describe "#find_disbursable_merchants" do
    let!(:daily_merchant) do
      Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
        reference: "DAILY123",
        email: "daily@example.com",
        live_on: Date.new(2024, 3, 20),
        disbursement_frequency: "daily",
        minimum_monthly_fee_cents: 1000
      )
    end

    let!(:weekly_merchant) do
      Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
        reference: "WEEKLY123",
        email: "weekly@example.com",
        live_on: Date.new(2024, 3, 20),
        disbursement_frequency: "weekly",
        minimum_monthly_fee_cents: 1000
      )
    end

    it "returns both daily and matching weekly merchants" do
      result = repository.find_disbursable_merchants(Date.new(2024, 3, 20))
      expect(result.map(&:reference)).to contain_exactly("DAILY123", "WEEKLY123")
      expect(result.first).to be_a(Domain::Merchants::Entities::DisbursableMerchant)
    end
  end

  describe "#find_disbursable_merchants_in_batches" do
    before do
      (Domain::Merchants::Repositories::MerchantRepository::BATCH_SIZE + 10).times do |i|
        Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
          reference: "MERCH#{i}",
          email: "merchant#{i}@example.com",
          live_on: Date.new(2024, 3, 20),
          disbursement_frequency: "daily",
          minimum_monthly_fee_cents: 1000
        )
      end
    end

    it "returns merchants in batches" do
      merchants = []
      repository.find_disbursable_merchants_in_batches(Date.new(2024, 3, 20)).each do |merchant|
        merchants << merchant
        expect(merchant).to be_a(Domain::Merchants::Entities::DisbursableMerchant)
      end
      expect(merchants.count).to eq(Domain::Merchants::Repositories::MerchantRepository::BATCH_SIZE + 10)
    end
  end
end
