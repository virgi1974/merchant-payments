require "rails_helper"

RSpec.describe Domain::Orders::Services::Importers::ApiImporter do
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

    let(:valid_params) do
      {
        merchant_reference: merchant.reference,
        amount: "100.50",
        created_at: "2024-03-20"
      }
    end

    before { merchant }

    context "with valid params" do
      it "creates an order record" do
        expect {
          described_class.call(valid_params)
        }.to change(Infrastructure::Persistence::ActiveRecord::Models::Order, :count).by(1)
      end

      it "returns an order entity" do
        order = described_class.call(valid_params)
        expect(order).to be_a(Domain::Orders::Entities::Order)
      end

      it "sets the correct attributes" do
        order = described_class.call(valid_params)
        expect(order.merchant_reference).to eq("MERCH123")
        expect(order.amount_cents).to eq(Money.new(10050).cents)
        expect(order.created_at).to eq(Date.new(2024, 3, 20))
      end

      it "logs creation process" do
        expect(Rails.logger).to receive(:info).with(/Starting order creation via API at/)
        expect(Rails.logger).to receive(:info).with(/Successfully created order with ID: /)

        described_class.call(valid_params)
      end
    end

    context "when validation fails" do
      let(:invalid_params) do
        {
          merchant_reference: "NONEXISTENT",
          amount: "-100.50",
          created_at: "not-a-date"
        }
      end

      it "raises ValidationError" do
        expect {
          described_class.call(invalid_params)
        }.to raise_error(Domain::Orders::Errors::ValidationError)
      end

      xit "logs the error" do
        expect(Rails.logger).to receive(:error).with(/Failed to create order:/)

        begin
          described_class.call(invalid_params)
        rescue Domain::Orders::Errors::ValidationError
          # Expected error
        end
      end
    end

    context "when unexpected error occurs" do
      before do
        allow(Domain::Orders::Services::OrderCreators::ApiCreator).to receive(:call)
          .and_raise(StandardError.new("Unexpected error"))
      end

      it "re-raises the error" do
        expect {
          described_class.call(valid_params)
        }.to raise_error(StandardError)
      end

      xit "logs the error message" do
        expect(Rails.logger).to receive(:error).with("Failed to create order: Unexpected error").once

        begin
          described_class.call(valid_params)
        rescue StandardError
          # Expected error
        end
      end
    end

    context "when duplicate detection is needed" do
      let(:first_order) { described_class.call(valid_params) }

      it "generates unique IDs for each order" do
        second_order = described_class.call(valid_params)
        expect(second_order.id).not_to eq(first_order.id)
      end

      it "allows multiple orders with same params but different IDs" do
        expect {
          described_class.call(valid_params)
          described_class.call(valid_params)
        }.to change(Infrastructure::Persistence::ActiveRecord::Models::Order, :count).by(2)
      end
    end
  end
end
