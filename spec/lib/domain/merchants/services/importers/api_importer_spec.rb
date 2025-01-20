require "rails_helper"

RSpec.describe Domain::Merchants::Services::Importers::ApiImporter do
  describe ".call" do
    let(:valid_params) do
      {
        reference: "MERCH123",
        email: "merchant@example.com",
        live_on: "2024-03-20",
        disbursement_frequency: "DAILY",
        minimum_monthly_fee: "10.00"
      }
    end

    context "with valid params" do
      it "creates a merchant record" do
        expect {
          described_class.call(valid_params)
        }.to change(Infrastructure::Persistence::ActiveRecord::Models::Merchant, :count).by(1)
      end

      it "returns a merchant entity" do
        merchant = described_class.call(valid_params)
        expect(merchant).to be_a(Domain::Merchants::Entities::Merchant)
      end

      it "sets the correct attributes" do
        merchant = described_class.call(valid_params)
        expect(merchant.reference).to eq("MERCH123")
        expect(merchant.email).to eq("merchant@example.com")
        expect(merchant.live_on).to eq(Date.new(2024, 3, 20))
        expect(merchant.disbursement_frequency).to eq("daily")
        expect(merchant.minimum_monthly_fee.cents).to eq(1000)
      end

      it "logs creation process" do
        expect(Rails.logger).to receive(:info).with(/Starting merchant creation via API at/)
        expect(Rails.logger).to receive(:info).with(/Successfully created merchant with ID: /)

        described_class.call(valid_params)
      end
    end

    context "when validation fails" do
      let(:invalid_params) do
        {
          reference: "MERCH123",
          email: "not-an-email",  # Invalid email format
          live_on: "not-a-date",  # Invalid date format
          disbursement_frequency: "INVALID",  # Invalid frequency
          minimum_monthly_fee: "-10.00"  # Invalid negative amount
        }
      end

      it "raises ValidationError" do
        expect {
          described_class.call(invalid_params)
        }.to raise_error(Domain::Merchants::Errors::ValidationError)
      end

      xit "logs the error" do
        expect(Rails.logger).to receive(:error).with(/Failed to create merchant:/)
      end
    end

    context "when merchant already exists" do
      before do
        described_class.call(valid_params)
      end

      it "raises RecordInvalid error" do
        expect {
          described_class.call(valid_params)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      xit "logs validation error message" do
        expect(Rails.logger).to receive(:error).with(/Failed to create merchant: Validation failed:/)

        begin
          described_class.call(valid_params)
        rescue ActiveRecord::RecordInvalid
          # Expected error
        end
      end
    end

    context "when unexpected error occurs" do
      before do
        allow(Domain::Merchants::Services::MerchantCreators::ApiCreator).to receive(:call)
          .and_raise(StandardError.new("Unexpected error"))
      end

      it "re-raises the error" do
        expect {
          described_class.call(valid_params)
        }.to raise_error(StandardError)
      end

      xit "logs the error message" do
        expect(Rails.logger).to receive(:error).with("Failed to create merchant: Unexpected error")

        begin
          described_class.call(valid_params)
        rescue StandardError
          # Expected error
        end
      end
    end
  end
end
