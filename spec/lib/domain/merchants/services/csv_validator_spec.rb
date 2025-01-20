require "rails_helper"

RSpec.describe Domain::Merchants::Services::CsvValidator do
  describe ".call" do
    let(:csv_path) { "spec/support/fixtures/test_merchants.csv" }
    let(:csv_content) do
      <<~CSV
        id,reference,email,live_on,disbursement_frequency,minimum_monthly_fee
        #{SecureRandom.uuid},MERCH123,merchant@example.com,2024-03-20,DAILY,10.00
      CSV
    end

    before do
      File.write(csv_path, csv_content)
    end

    after do
      File.delete(csv_path) if File.exist?(csv_path)
    end

    it "validates a valid CSV file" do
      result = described_class.call(csv_path)
      expect(result).to include(
        valid: true,
        errors: [],
        separator: ","
      )
    end

    context "with missing file" do
      let(:non_existent_path) { "non_existent.csv" }

      it "returns error for missing file" do
        result = described_class.call(non_existent_path)
        expect(result).to include(
          valid: false,
          errors: [ "CSV file not found: #{non_existent_path}" ],
          separator: nil
        )
      end
    end

    context "with invalid headers" do
      let(:csv_content) do
        <<~CSV
          id,reference,wrong_field,live_on
          #{SecureRandom.uuid},MERCH123,value,2024-03-20
        CSV
      end

      it "returns error for missing required headers" do
        result = described_class.call(csv_path)
        expect(result).to include(
          valid: false,
          separator: ","
        )
        expect(result[:errors].first).to include("Missing required headers")
      end
    end

    context "with different valid separators" do
      {
        "comma" => ",",
        "semicolon" => ";",
        "tab" => "\t"
      }.each do |name, separator|
        context "with #{name} separator" do
          let(:csv_content) do
            headers = %w[id reference email live_on disbursement_frequency minimum_monthly_fee].join(separator)
            values = [ SecureRandom.uuid, "MERCH123", "merchant@example.com", "2024-03-20", "DAILY", "10.00" ].join(separator)
            [ headers, values ].join("\n")
          end

          it "detects and validates correctly" do
            result = described_class.call(csv_path)
            expect(result).to include(
              valid: true,
              errors: [],
              separator: separator
            )
          end
        end
      end
    end

    context "with invalid separator" do
      let(:csv_content) do
        <<~CSV
          id|reference|email|live_on|disbursement_frequency|minimum_monthly_fee
          #{SecureRandom.uuid}|MERCH123|merchant@example.com|2024-03-20|DAILY|10.00
        CSV
      end

      it "returns error for invalid CSV format" do
        result = described_class.call(csv_path)
        expect(result).to include(
          valid: false,
          errors: include(a_string_matching(/Invalid CSV format/)),
          separator: nil
        )
      end
    end

    context "with malformed CSV" do
      let(:csv_content) { "this is not,a valid\nCSV,file\"with,broken\"quotes" }

      it "returns error for malformed CSV" do
        result = described_class.call(csv_path)
        expect(result).to include(
          valid: false,
          errors: include(a_string_matching(/Invalid CSV format/))
        )
      end
    end

    context "with empty file" do
      let(:csv_content) { "" }

      it "returns error for empty file" do
        result = described_class.call(csv_path)
        expect(result).to include(
          valid: false,
          errors: [ "CSV file is empty" ],
          separator: nil
        )
      end
    end
  end
end
