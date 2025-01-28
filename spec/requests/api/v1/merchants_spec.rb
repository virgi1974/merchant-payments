require "swagger_helper"

RSpec.describe "Merchants API", type: :request do
  path "/api/v1/merchants" do
    post("create merchant") do
      tags "Merchants"
      consumes "application/json"
      produces "application/json"

      parameter name: :merchant, in: :body, schema: {
        type: :object,
        properties: {
          reference: { type: :string, example: "MERCH123" },
          email: { type: :string, example: "merchant@example.com" },
          live_on: { type: :string, format: "date", example: "2024-03-20" },
          disbursement_frequency: { type: :string, enum: [ "DAILY", "WEEKLY" ], example: "WEEKLY" },
          minimum_monthly_fee: { type: :number, format: :float, example: 29.99 }
        },
        required: [ :reference, :email, :live_on, :disbursement_frequency ]
      }

      response(201, "merchant created") do
        let(:merchant) do
          {
            reference: "MERCH123",
            email: "merchant@example.com",
            live_on: "2024-03-20",
            disbursement_frequency: "DAILY",
            minimum_monthly_fee: 29.99
          }
        end
        run_test!
      end

      response(422, "unprocessable entity") do
        let(:merchant) { { reference: nil } }
        run_test!
      end
    end
  end
end
