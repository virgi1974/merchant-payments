require "rails_helper"

RSpec.describe Domain::Merchants::Services::MerchantCreators::CsvCreator do
  describe ".call" do
    let(:merchant_data) do
      Domain::Merchants::Data::CsvRecordValidator.new(
        id: SecureRandom.uuid,
        reference: "MERCH123",
        email: "merchant@example.com",
        live_on: Date.new(2024, 3, 20),
        disbursement_frequency: "DAILY",
        minimum_monthly_fee: BigDecimal("10.00")
      )
    end

    it "inherits from BaseCreator" do
      expect(described_class).to be < Domain::Merchants::Services::MerchantCreators::BaseCreator
    end

    it "creates a merchant record" do
      expect {
        described_class.call(merchant_data)
      }.to change(Infrastructure::Persistence::ActiveRecord::Models::Merchant, :count).by(1)
    end

    it "returns a merchant entity" do
      merchant = described_class.call(merchant_data)
      expect(merchant).to be_a(Domain::Merchants::Entities::Merchant)
      expect(merchant.reference).to eq("MERCH123")
    end

    it "sets the correct attributes" do
      merchant = described_class.call(merchant_data)
      expect(merchant.reference).to eq("MERCH123")
      expect(merchant.email).to eq("merchant@example.com")
      expect(merchant.live_on).to eq(Date.new(2024, 3, 20))
      expect(merchant.disbursement_frequency).to eq("daily")
      expect(merchant.minimum_monthly_fee.cents).to eq(1000)
    end

    context "when validation fails" do
      it "raises error for invalid disbursement frequency" do
        allow(Domain::Merchants::ValueObjects::DisbursementFrequency)
          .to receive(:valid?)
          .with(merchant_data.disbursement_frequency)
          .and_return(false)

        expect {
          described_class.call(merchant_data)
        }.to raise_error(Domain::Merchants::Errors::InvalidDisbursementFrequency)
      end

      it "raises error for negative minimum monthly fee" do
        allow(merchant_data)
          .to receive(:minimum_monthly_fee)
          .and_return(BigDecimal("-10.00"))

        expect {
          described_class.call(merchant_data)
        }.to raise_error(Domain::Merchants::Errors::InvalidMinimumMonthlyFee)
      end
    end

    context "when merchant already exists" do
      before do
        described_class.call(merchant_data)
      end

      it "raises RecordInvalid error" do
        expect {
          described_class.call(merchant_data)
        }.to raise_error(ActiveRecord::RecordInvalid, /Reference has already been taken/)
      end
    end
  end
end
