require "rails_helper"

RSpec.describe Domain::Merchants::Data::ApiRecordValidator do
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
      it "returns a validator instance" do
        result = described_class.call(valid_params)
        expect(result).to be_a(described_class)
      end

      it "transforms the attributes correctly" do
        result = described_class.call(valid_params)
        expect(result.reference).to eq("MERCH123")
        expect(result.email).to eq("merchant@example.com")
        expect(result.live_on).to eq(Date.new(2024, 3, 20))
        expect(result.disbursement_frequency).to eq("DAILY")
        expect(result.minimum_monthly_fee).to eq(BigDecimal("10.00"))
      end
    end

    context "with invalid params" do
      it "raises error for missing required fields" do
        expect {
          described_class.call({})
        }.to raise_error(Dry::Struct::Error)
      end

      it "raises error for invalid email" do
        expect {
          described_class.call(valid_params.merge(email: "not-an-email"))
        }.to raise_error(Dry::Struct::Error)
      end

      it "raises error for invalid date format" do
        expect {
          described_class.call(valid_params.merge(live_on: "not-a-date"))
        }.to raise_error(Dry::Struct::Error)
      end

      it "raises error for invalid disbursement frequency" do
        expect {
          described_class.call(valid_params.merge(disbursement_frequency: "INVALID"))
        }.to raise_error(Dry::Struct::Error)
      end

      it "raises error for invalid money amount" do
        expect {
          described_class.call(valid_params.merge(minimum_monthly_fee: "not-money"))
        }.to raise_error(Dry::Struct::Error)
      end
    end
  end
end
