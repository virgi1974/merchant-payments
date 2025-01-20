require "rails_helper"

RSpec.describe Infrastructure::Presenters::Api::V1::MerchantPresenter do
  describe ".created" do
    let(:merchant) do
      Domain::Merchants::Entities::Merchant.new(
        id: SecureRandom.uuid,
        reference: "MERCH123",
        email: "merchant@example.com",
        live_on: Date.current,
        disbursement_frequency: :daily,
        minimum_monthly_fee_cents: 1000
      )
    end

    it "returns success response with merchant id" do
      response = described_class.created(merchant)
      expect(response).to eq(
        json: { id: merchant.id },
        status: :created
      )
    end
  end

  describe ".error" do
    it "returns error response with message and status" do
      response = described_class.error("Something went wrong", :unprocessable_entity)
      expect(response).to eq(
        json: { error: "Something went wrong" },
        status: :unprocessable_entity
      )
    end
  end
end
