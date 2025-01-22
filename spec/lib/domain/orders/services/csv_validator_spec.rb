require "rails_helper"

RSpec.describe Domain::Orders::Services::CsvValidator do
  describe ".call" do
    let(:csv_path) { "spec/support/fixtures/test_orders.csv" }
    let(:csv_content) do
      <<~CSV
        id,merchant_reference,amount,created_at
        #{SecureRandom.hex(6)},MERCH123,100.50,2024-03-20
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
          id,merchant_reference,wrong_field,created_at
          #{SecureRandom.hex(6)},MERCH123,value,2024-03-20
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
            headers = %w[id merchant_reference amount created_at].join(separator)
            values = [ SecureRandom.hex(6), "MERCH123", "100.50", "2024-03-20" ].join(separator)
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
          id|merchant_reference|amount|created_at
          #{SecureRandom.hex(6)}|MERCH123|100.50|2024-03-20
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
