require "swagger_helper"

RSpec.describe "Orders API", type: :request do
  path "/api/v1/orders" do
    post("create order") do
      tags "Orders"
      consumes "application/json"
      produces "application/json"

      parameter name: :order, in: :body, schema: {
        type: :object,
        properties: {
          merchant_reference: { type: :string, example: "ORDER123" },
          amount: { type: :number, format: :float, example: 100.50 },
          created_at: { type: :string, format: "date-time", example: "2024-03-20T10:00:00Z" }
        },
        required: [ :merchant_reference, :amount, :created_at ]
      }

      response(201, "order created") do
        let!(:merchant) do
          Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
            reference: "ORDER123",
            email: "merchant@test.com",
            live_on: "2024-01-01",
            disbursement_frequency: "daily",
            minimum_monthly_fee_cents: 2900
          )
        end
        let(:order) { { merchant_reference: "ORDER123", amount: 100.50, created_at: "2024-03-20T10:00:00Z" } }
        run_test!
      end

      response(422, "unprocessable entity") do
        let(:order) { { merchant_reference: nil } }
        run_test!
      end
    end
  end
end
