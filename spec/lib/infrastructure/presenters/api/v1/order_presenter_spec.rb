require "rails_helper"

RSpec.describe Infrastructure::Presenters::Api::V1::OrderPresenter do
  describe ".created" do
    let(:order) do
      Domain::Orders::Entities::Order.new(
        id: SecureRandom.hex(6),
        merchant_reference: "MERCH123",
        amount_cents: 10000,
        amount_currency: "EUR",
        created_at: Time.current
      )
    end

    it "returns success response with order id" do
      response = described_class.created(order)
      expect(response).to eq(
        json: { id: order.id },
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
