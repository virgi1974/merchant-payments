require "rails_helper"

RSpec.describe Domain::Merchants::Services::MerchantCreators::BaseCreator do
  let(:test_creator) { Class.new(described_class) }
  let(:merchant_data) do
    instance_double(
      "MerchantData",
      id: SecureRandom.uuid,
      reference: "MERCH123",
      email: "merchant@example.com",
      live_on: Date.new(2024, 3, 20),
      disbursement_frequency: "DAILY",
      minimum_monthly_fee: BigDecimal("10.00")
    )
  end

  describe ".call" do
    context "when called on BaseCreator directly" do
      it "raises NotImplementedError" do
        expect {
          described_class.call(merchant_data)
        }.to raise_error(NotImplementedError, /is an abstract class/)
      end
    end
  end

  describe "#initialize" do
    context "when instantiating BaseCreator directly" do
      it "raises NotImplementedError" do
        expect {
          described_class.new(merchant_data)
        }.to raise_error(NotImplementedError, /is an abstract class/)
      end
    end
  end

  describe "#call" do
    it "validates and creates merchant" do
      creator = test_creator.new(merchant_data)
      expect(creator).to receive(:validate_merchant_data)
      expect(creator).to receive(:normalize_merchant_data)
      expect(creator).to receive(:create_merchant)
      creator.call
    end
  end

  describe "validations" do
    context "when disbursement frequency is invalid" do
      before do
        allow(Domain::Merchants::ValueObjects::DisbursementFrequency)
          .to receive(:valid?)
          .with(merchant_data.disbursement_frequency)
          .and_return(false)
      end

      it "raises InvalidDisbursementFrequency" do
        expect {
          test_creator.call(merchant_data)
        }.to raise_error(Domain::Merchants::Errors::InvalidDisbursementFrequency)
      end
    end

    context "when minimum monthly fee is negative" do
      before do
        allow(merchant_data)
          .to receive(:minimum_monthly_fee)
          .and_return(BigDecimal("-10.00"))
      end

      it "raises InvalidMinimumMonthlyFee" do
        expect {
          test_creator.call(merchant_data)
        }.to raise_error(Domain::Merchants::Errors::InvalidMinimumMonthlyFee)
      end
    end
  end

  describe "data normalization" do
    let(:normalized_data) do
      {
        id: merchant_data.id,
        reference: merchant_data.reference,
        email: merchant_data.email,
        disbursement_frequency: :daily,
        minimum_monthly_fee_cents: 1000,
        live_on: merchant_data.live_on
      }
    end

    it "normalizes merchant data correctly" do
      creator = test_creator.new(merchant_data)
      allow(creator).to receive(:create_merchant)
      allow(Domain::Merchants::ValueObjects::DisbursementFrequency)
        .to receive(:normalize)
        .with("DAILY")
        .and_return(:daily)

      expect(creator).to receive(:create_merchant).with(normalized_data)
      creator.call
    end
  end

  describe "error handling" do
    context "when merchant already exists" do
      before do
        allow_any_instance_of(Domain::Merchants::Repositories::MerchantRepository)
          .to receive(:create)
          .and_raise(ActiveRecord::RecordInvalid)
      end

      it "raises RecordInvalid error" do
        expect {
          test_creator.call(merchant_data)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "when database operation fails" do
      before do
        allow_any_instance_of(Domain::Merchants::Repositories::MerchantRepository)
          .to receive(:create)
          .and_raise(StandardError, "Database connection lost")
      end

      it "propagates the error" do
        expect {
          test_creator.call(merchant_data)
        }.to raise_error(StandardError, "Database connection lost")
      end
    end
  end
end
