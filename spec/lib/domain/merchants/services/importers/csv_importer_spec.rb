require "rails_helper"

RSpec.describe Domain::Merchants::Services::Importers::CsvImporter do
  describe ".call" do
    let(:csv_path) { "spec/support/fixtures/valid_merchants.csv" }
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

    it "creates merchant records from CSV" do
      expect {
        described_class.call(csv_path)
      }.to change(Infrastructure::Persistence::ActiveRecord::Models::Merchant, :count).by(1)
    end

    it "returns success response with import details" do
      result = described_class.call(csv_path)
      expect(result).to include(
        success: true,
        imported_count: 1,
        failed_count: 0,
        failures: []
      )
    end

    context "with invalid CSV format" do
      let(:csv_content) { "invalid,csv,format" }

      it "returns error response" do
        result = described_class.call(csv_path)
        expect(result).to include(
          success: false,
          errors: be_a(Array)
        )
        expect(result[:errors].first).to include("Missing required headers")
      end
    end

    context "with missing file" do
      let(:non_existent_path) { "non_existent.csv" }

      it "returns error response" do
        result = described_class.call(non_existent_path)
        expect(result).to include(
          success: false,
          errors: be_a(Array)
        )
        expect(result[:errors].first).to include("CSV file not found")
      end
    end

    context "with invalid merchant data" do
      let(:csv_content) do
        <<~CSV
          id,reference,email,live_on,disbursement_frequency,minimum_monthly_fee
          #{SecureRandom.uuid},MERCH123,invalid-email,2024-03-20,INVALID,-10.00
        CSV
      end

      it "returns failure details and rolls back transaction" do
        result = described_class.call(csv_path)
        expect(result).to include(
          success: true,
          imported_count: 0,
          failed_count: 1
        )

        failure = result[:failures].first
        expect(failure).to include(
          line: 2,
          error: include("invalid-email"),
          data: include(
            "reference" => "MERCH123",
            "email" => "invalid-email"
          )
        )
        expect(Infrastructure::Persistence::ActiveRecord::Models::Merchant.count).to eq(0)
      end
    end

    context "when merchant already exists" do
      before do
        described_class.call(csv_path)
      end

      it "returns failure details and rolls back transaction" do
        result = described_class.call(csv_path)
        expect(result).to include(
          success: true,
          imported_count: 0,
          failed_count: 1
        )

        failure = result[:failures].first
        expect(failure).to include(
          line: 2,
          error: include("has already been taken"),
          data: include(
            "reference" => "MERCH123",
            "email" => "merchant@example.com"
          )
        )
        expect(Infrastructure::Persistence::ActiveRecord::Models::Merchant.count).to eq(1)
      end
    end

    context "when database operation fails" do
      before do
        allow_any_instance_of(Domain::Merchants::Repositories::MerchantRepository)
          .to receive(:create)
          .and_raise(StandardError, "Database connection lost")
      end

      it "returns failure details and rolls back transaction" do
        result = described_class.call(csv_path)
        expect(result).to include(
          success: true,
          imported_count: 0,
          failed_count: 1
        )

        failure = result[:failures].first
        expect(failure).to include(
          line: 2,
          error: "Database connection lost",
          data: include(
            "reference" => "MERCH123",
            "email" => "merchant@example.com"
          )
        )
        expect(Infrastructure::Persistence::ActiveRecord::Models::Merchant.count).to eq(0)
      end
    end

    context "with empty CSV file" do
      let(:csv_content) do
        <<~CSV
          id,reference,email,live_on,disbursement_frequency,minimum_monthly_fee
        CSV
      end

      it "returns success with zero imports" do
        result = described_class.call(csv_path)
        expect(result).to include(
          success: true,
          imported_count: 0,
          failed_count: 0,
          failures: []
        )
      end
    end

    context "with multiple valid records" do
      let(:csv_content) do
        <<~CSV
          id,reference,email,live_on,disbursement_frequency,minimum_monthly_fee
          #{SecureRandom.uuid},MERCH123,merchant1@example.com,2024-03-20,DAILY,10.00
          #{SecureRandom.uuid},MERCH456,merchant2@example.com,2024-03-21,WEEKLY,20.00
        CSV
      end

      it "imports all records successfully" do
        result = described_class.call(csv_path)
        expect(result).to include(
          success: true,
          imported_count: 2,
          failed_count: 0,
          failures: []
        )
        expect(Infrastructure::Persistence::ActiveRecord::Models::Merchant.count).to eq(2)
      end
    end

    context "with mixed valid and invalid records" do
      let(:csv_content) do
        <<~CSV
          id,reference,email,live_on,disbursement_frequency,minimum_monthly_fee
          #{SecureRandom.uuid},MERCH123,merchant@example.com,2024-03-20,DAILY,10.00
          #{SecureRandom.uuid},MERCH456,invalid-email,2024-03-21,WEEKLY,20.00
        CSV
      end

      it "imports valid records and reports failures" do
        result = described_class.call(csv_path)
        expect(result).to include(
          success: true,
          imported_count: 1,
          failed_count: 1
        )
        expect(result[:failures].first).to include(
          line: 3,
          error: include("invalid-email"),
          data: include("reference" => "MERCH456")
        )
        expect(Infrastructure::Persistence::ActiveRecord::Models::Merchant.count).to eq(1)
      end
    end
  end
end
