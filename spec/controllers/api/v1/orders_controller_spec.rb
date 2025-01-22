require "rails_helper"

RSpec.describe Api::V1::OrdersController, type: :controller do
  describe "POST #create" do
    let(:valid_params) do
      {
        merchant_reference: "MERCH123",
        amount: "100.50",
        created_at: Date.current.to_s
      }
    end

    context "with valid params" do
      it "creates a new order" do
        order = double("order", id: SecureRandom.hex(6))
        expect(Domain::Orders::Services::Importers::ApiImporter).to receive(:call)
          .with(valid_params.stringify_keys)
          .and_return(order)

        post :create, params: valid_params
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)).to include("id")
      end
    end

    context "with missing parameters" do
      it "returns unprocessable_entity status" do
        post :create, params: { merchant_reference: "MERCH123" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to include("Invalid order data")
      end
    end

    context "with validation errors" do
      before do
        allow(Domain::Orders::Services::Importers::ApiImporter).to receive(:call)
          .and_raise(Domain::Orders::Errors::ValidationError.new("Invalid data"))
      end

      it "returns unprocessable_entity status" do
        post :create, params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to include("Invalid data")
      end
    end

    context "with invalid record" do
      before do
        allow(Domain::Orders::Services::Importers::ApiImporter).to receive(:call)
          .and_raise(ActiveRecord::RecordInvalid.new)
      end

      it "returns unprocessable_entity status" do
        post :create, params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to eq("Invalid data: Record invalid")
      end
    end

    context "with unexpected error" do
      before do
        allow(Domain::Orders::Services::Importers::ApiImporter).to receive(:call)
          .and_raise(StandardError.new("Unexpected error"))
      end

      it "returns internal_server_error status" do
        post :create, params: valid_params
        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)["error"]).to eq("Something went wrong")
      end
    end

    context "with unpermitted parameters" do
      let(:tampered_id) { SecureRandom.uuid }
      let(:params_with_id) do
        valid_params.merge(id: tampered_id)
      end

      it "ignores unpermitted parameters" do
        order = double("order", id: SecureRandom.hex(6))
        allow(Domain::Orders::Services::Importers::ApiImporter).to receive(:call)
          .and_return(order)

        post :create, params: params_with_id
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)["id"]).not_to eq(tampered_id)
      end
    end

    context "when order already exists" do
      before do
        allow(Domain::Orders::Services::Importers::ApiImporter).to receive(:call)
          .and_raise(ActiveRecord::RecordNotUnique.new("Duplicate entry"))
      end

      it "returns conflict status" do
        post :create, params: valid_params
        expect(response).to have_http_status(:conflict)
        expect(JSON.parse(response.body)["error"]).to eq("Order already exists")
      end
    end
  end
end
