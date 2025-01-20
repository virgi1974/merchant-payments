require "rails_helper"

RSpec.describe Api::V1::MerchantsController, type: :controller do
  describe "POST #create" do
    let(:valid_params) do
      {
        reference: "MERCH123",
        email: "merchant@example.com",
        live_on: "2024-03-20",
        disbursement_frequency: "DAILY",
        minimum_monthly_fee: "10.00"
      }
    end

    context "with valid params" do
      it "creates a new merchant" do
        merchant = double("merchant", id: SecureRandom.uuid)
        expect(Domain::Merchants::Services::ApiImporter).to receive(:call)
          .with(valid_params.stringify_keys)
          .and_return(merchant)

        post :create, params: valid_params
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)).to include("id")
      end
    end

    context "with missing parameters" do
      it "returns unprocessable_entity status" do
        post :create, params: { reference: "MERCH123" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to include("Invalid merchant data")
      end
    end

    context "with validation errors" do
      before do
        allow(Domain::Merchants::Services::ApiImporter).to receive(:call)
          .and_raise(Domain::Merchants::Errors::ValidationError.new("Invalid data"))
      end

      it "returns unprocessable_entity status" do
        post :create, params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to include("Invalid data")
      end
    end

    context "with duplicate merchant" do
      before do
        allow(Domain::Merchants::Services::ApiImporter).to receive(:call)
          .and_raise(ActiveRecord::RecordNotUnique.new("Duplicate"))
      end

      it "returns conflict status" do
        post :create, params: valid_params
        expect(response).to have_http_status(:conflict)
        expect(JSON.parse(response.body)["error"]).to eq("Merchant already exists")
      end
    end

    context "with unexpected error" do
      before do
        allow(Domain::Merchants::Services::ApiImporter).to receive(:call)
          .and_raise(StandardError.new("Unexpected error"))
      end

      it "returns internal_server_error status" do
        post :create, params: valid_params
        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)["error"]).to eq("Something went wrong")
      end
    end

    context "with invalid record" do
      before do
        allow(Domain::Merchants::Services::ApiImporter).to receive(:call)
          .and_raise(ActiveRecord::RecordInvalid.new)
      end

      it "returns unprocessable_entity status" do
        post :create, params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to eq("Invalid data: Record invalid")
      end
    end

    context "with unpermitted parameters" do
      let(:tampered_id) { SecureRandom.uuid }
      let(:params_with_id) do
        valid_params.merge(id: tampered_id)
      end

      it "ignores unpermitted parameters" do
        merchant = double("merchant", id: SecureRandom.uuid)
        allow(Domain::Merchants::Services::ApiImporter).to receive(:call)
          .and_return(merchant)

        post :create, params: params_with_id
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)["id"]).not_to eq(tampered_id)
      end
    end
  end
end
