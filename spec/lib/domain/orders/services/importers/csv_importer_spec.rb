require "rails_helper"

RSpec.describe Domain::Orders::Services::Importers::CsvImporter do
  describe ".call" do
    let(:merchant) do
      Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
        reference: "MERCH123",
        email: "merchant@example.com",
        live_on: Date.current,
        disbursement_frequency: "daily",
        minimum_monthly_fee_cents: 1000
      )
    end

    let(:csv_path) { "spec/support/fixtures/valid_orders.csv" }
    let(:csv_content) do
      <<~CSV
        id,merchant_reference,amount,created_at
        #{SecureRandom.hex(6)},MERCH123,100.50,2024-03-20
      CSV
    end

    before do
      merchant
      File.write(csv_path, csv_content)
    end

    after do
      File.delete(csv_path) if File.exist?(csv_path)
    end

    it "creates order records from CSV" do
      expect {
        described_class.call(csv_path)
      }.to change(Infrastructure::Persistence::ActiveRecord::Models::Order, :count).by(1)
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
          error: include("Missing required headers")
        )
      end
    end

    context "with missing file" do
      let(:non_existent_path) { "non_existent.csv" }

      it "returns error response" do
        result = described_class.call(non_existent_path)
        expect(result).to include(
          success: false,
          error: include("CSV file not found")
        )
      end
    end

    context "with invalid order data" do
      let(:csv_content) do
        <<~CSV
          id,merchant_reference,amount,created_at
          #{SecureRandom.hex(6)},NONEXISTENT,-100.50,not-a-date
        CSV
      end

      it "returns failure details" do
        result = described_class.call(csv_path)
        expect(result).to include(
          success: true,
          imported_count: 0,
          failed_count: 1
        )

        failure = result[:failures].first
        expect(failure).to include(
          line: 1,
          error: be_a(String),
          data: include(
            "merchant_reference" => "NONEXISTENT",
            "amount" => "-100.50",
            "created_at" => "not-a-date"
          )
        )
        expect(Infrastructure::Persistence::ActiveRecord::Models::Order.count).to eq(0)
      end
    end

    context "when database operation fails" do
      before do
        allow(Domain::Orders::Services::OrderCreators::CsvCreator)
          .to receive(:call)
          .and_raise(StandardError, "Database connection lost")
      end

      it "returns failure details" do
        result = described_class.call(csv_path)
        expect(result).to include(
          success: true,
          imported_count: 0,
          failed_count: 1
        )

        failure = result[:failures].first
        expect(failure).to include(
          line: 1,
          error: "Database connection lost",
          data: include(
            "merchant_reference" => "MERCH123",
            "amount" => "100.50",
            "created_at" => "2024-03-20"
          )
        )
        expect(Infrastructure::Persistence::ActiveRecord::Models::Order.count).to eq(0)
      end
    end

    context "with empty CSV file" do
      let(:csv_content) do
        <<~CSV
          id,merchant_reference,amount,created_at
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
          id,merchant_reference,amount,created_at
          #{SecureRandom.hex(6)},MERCH123,100.50,2024-03-20
          #{SecureRandom.hex(6)},MERCH123,200.75,2024-03-21
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
        expect(Infrastructure::Persistence::ActiveRecord::Models::Order.count).to eq(2)
      end
    end

    context "with mixed valid and invalid records" do
      let(:csv_content) do
        <<~CSV
          id,merchant_reference,amount,created_at
          #{SecureRandom.hex(6)},MERCH123,100.50,2024-03-20
          #{SecureRandom.hex(6)},NONEXISTENT,200.75,2024-03-21
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
          line: 1,
          error: be_present,
          data: include(
            "merchant_reference" => "NONEXISTENT",
            "amount" => "200.75",
            "created_at" => "2024-03-21"
          )
        )
        expect(Infrastructure::Persistence::ActiveRecord::Models::Order.count).to eq(1)
      end
    end

    context "with duplicate IDs" do
      let(:duplicate_id) { SecureRandom.hex(6) }
      let(:csv_content) do
        <<~CSV
          id,merchant_reference,amount,created_at
          #{duplicate_id},MERCH123,100.50,2024-03-20
          #{duplicate_id},MERCH123,200.75,2024-03-21
        CSV
      end

      it "imports first record and reports duplicate ID failure" do
        result = described_class.call(csv_path)
        expect(result).to include(
          success: true,
          imported_count: 1,
          failed_count: 1
        )
        expect(result[:failures].first).to include(
          line: 1,
          error: "SQLite3::ConstraintException: UNIQUE constraint failed: orders.id",
          data: include(
            "id" => duplicate_id,
            "merchant_reference" => "MERCH123",
            "amount" => "200.75",
            "created_at" => "2024-03-21"
          )
        )
        expect(Infrastructure::Persistence::ActiveRecord::Models::Order.count).to eq(1)
      end
    end
  end
end
