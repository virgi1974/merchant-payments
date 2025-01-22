require "rails_helper"

RSpec.describe Domain::Orders::Data::CsvRecordValidator do
  describe ".call" do
    let(:valid_row) do
      {
        "id" => SecureRandom.hex(6),
        "merchant_reference" => "MERCH123",
        "amount" => "100.50",
        "created_at" => "2024-03-20"
      }
    end

    context "with valid row" do
      it "returns a validator instance" do
        validator = described_class.call(",")
        result = validator.process_row(valid_row)
        expect(result).to be_a(described_class)
      end

      it "transforms the attributes correctly" do
        validator = described_class.call(",")
        result = validator.process_row(valid_row)

        expect(result.id).to be_a(String)
        expect(result.merchant_reference).to eq("MERCH123")
        expect(result.amount).to eq(BigDecimal("100.50"))
        expect(result.created_at).to eq(Date.new(2024, 3, 20))
      end
    end

    context "with invalid row" do
      it "raises error for invalid merchant reference" do
        validator = described_class.call(",")
        expect {
          validator.process_row(valid_row.merge("merchant_reference" => 123))
        }.to raise_error(Dry::Struct::Error, /123/)
      end

      it "raises error for invalid date" do
        validator = described_class.call(",")
        expect {
          validator.process_row(valid_row.merge("created_at" => "not-a-date"))
        }.to raise_error(Dry::Struct::Error, /not-a-date/)
      end

      it "raises error for invalid amount" do
        validator = described_class.call(",")
        expect {
          validator.process_row(valid_row.merge("amount" => "not-a-number"))
        }.to raise_error(Dry::Struct::Error, /not-a-number/)
      end

      it "raises error for negative amount" do
        validator = described_class.call(",")
        expect {
          validator.process_row(valid_row.merge("amount" => "-100.50"))
        }.to raise_error(Dry::Struct::Error, /-100.50/)
      end
    end

    context "with missing fields" do
      it "raises error for missing required fields" do
        validator = described_class.call(",")
        expect {
          validator.process_row({})
        }.to raise_error(Dry::Struct::Error)
      end
    end

    context "with error messages" do
      it "includes row data in error message" do
        validator = described_class.call(",")
        invalid_row = valid_row.merge("amount" => "not-a-number")

        error_message = begin
          validator.process_row(invalid_row)
        rescue Dry::Struct::Error => e
          e.message
        end

        expect(error_message).to include("Row: {")
        expect(error_message).to include(invalid_row["merchant_reference"])
        expect(error_message).to include("not-a-number")
      end
    end

    context "with separator" do
      it "stores the separator" do
        validator = described_class.call(";")
        expect(validator.send(:separator)).to eq(";")
      end
    end
  end
end
