require "rails_helper"

RSpec.describe Domain::Merchants::Data::CsvRecordValidator do
  describe ".call" do
    let(:valid_row) do
      {
        "id" => SecureRandom.uuid,
        "reference" => "MERCH123",
        "email" => "merchant@example.com",
        "live_on" => "2024-03-20",
        "disbursement_frequency" => "DAILY",
        "minimum_monthly_fee" => "10.00"
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
        expect(result.reference).to eq("MERCH123")
        expect(result.email).to eq("merchant@example.com")
        expect(result.live_on).to eq(Date.new(2024, 3, 20))
        expect(result.disbursement_frequency).to eq("DAILY")
        expect(result.minimum_monthly_fee).to eq(BigDecimal("10.00"))
      end
    end

    context "with invalid row" do
      it "raises error for invalid email" do
        validator = described_class.call(",")
        expect {
          validator.process_row(valid_row.merge("email" => "not-an-email"))
        }.to raise_error(Dry::Struct::Error, /not-an-email/)
      end

      it "raises error for invalid date" do
        validator = described_class.call(",")
        expect {
          validator.process_row(valid_row.merge("live_on" => "not-a-date"))
        }.to raise_error(Dry::Struct::Error, /not-a-date/)
      end

      it "raises error for invalid disbursement frequency" do
        validator = described_class.call(",")
        expect {
          validator.process_row(valid_row.merge("disbursement_frequency" => "INVALID"))
        }.to raise_error(Dry::Struct::Error, /INVALID/)
      end

      it "raises error for invalid minimum monthly fee" do
        validator = described_class.call(",")
        expect {
          validator.process_row(valid_row.merge("minimum_monthly_fee" => "not-a-number"))
        }.to raise_error(Dry::Struct::Error, /not-a-number/)
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
        invalid_row = valid_row.merge("email" => "not-an-email")

        error_message = begin
          validator.process_row(invalid_row)
        rescue Dry::Struct::Error => e
          e.message
        end

        expect(error_message).to include("Row: {")
        expect(error_message).to include(invalid_row["reference"])
        expect(error_message).to include("not-an-email")
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
