require "rails_helper"

RSpec.describe Domain::Orders::Data::ApiRecordValidator do
  describe ".call" do
    let(:valid_params) do
      {
        merchant_reference: "MERCH123",
        amount: "100.50",
        created_at: "2024-03-20"
      }
    end

    context "with valid params" do
      it "returns a validator instance" do
        result = described_class.call(valid_params)
        expect(result).to be_a(described_class)
      end

      it "transforms the attributes correctly" do
        result = described_class.call(valid_params)
        expect(result.id).to be_nil
        expect(result.merchant_reference).to eq("MERCH123")
        expect(result.amount).to eq(BigDecimal("100.50"))
        expect(result.created_at).to eq(Date.new(2024, 3, 20))
      end
    end

    context "with invalid params" do
      it "raises error for missing required fields" do
        expect {
          described_class.call({})
        }.to raise_error(Dry::Struct::Error)
      end

      it "raises error for invalid merchant reference format" do
        expect {
          described_class.call(valid_params.merge(merchant_reference: 123))
        }.to raise_error(Dry::Struct::Error)
      end

      it "raises error for invalid date format" do
        expect {
          described_class.call(valid_params.merge(created_at: "not-a-date"))
        }.to raise_error(Dry::Struct::Error)
      end

      it "raises error for invalid amount" do
        expect {
          described_class.call(valid_params.merge(amount: "not-money"))
        }.to raise_error(Dry::Struct::Error)
      end

      it "raises error for negative amount" do
        expect {
          described_class.call(valid_params.merge(amount: "-100.50"))
        }.to raise_error(Dry::Struct::Error)
      end
    end
  end
end
