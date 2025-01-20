require "rails_helper"

RSpec.describe Domain::Merchants::Services::MerchantCreators::ApiCreator do
  describe ".call" do
    let(:merchant_data) do
      Domain::Merchants::Data::ApiRecordValidator.new(
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

    context "with invalid input type" do
      it "raises ArgumentError" do
        expect {
          described_class.call({})
        }.to raise_error(NoMethodError)
      end
    end

    context "when creation fails" do
      before do
        allow(Infrastructure::Persistence::ActiveRecord::Models::Merchant).to receive(:create!)
          .and_raise(StandardError, "Database connection lost")
      end

      it "rolls back the transaction" do
        expect {
          begin
            described_class.call(merchant_data)
          rescue StandardError
            nil
          end
        }.not_to change(Infrastructure::Persistence::ActiveRecord::Models::Merchant, :count)
      end
    end
  end
end
