require "rails_helper"

RSpec.describe Domain::Disbursements::Repositories::DisbursementRepository do
  subject(:repository) { described_class.new }

  let(:merchant) do
    Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
      reference: "merchant_1",
      email: "merchant@test.com",
      live_on: "2024-01-01",
      disbursement_frequency: "daily",
      minimum_monthly_fee_cents: 0
    )
  end

  let(:order) do
    Infrastructure::Persistence::ActiveRecord::Models::Order.create!(
      id: "order_1",
      merchant_reference: merchant.reference,
      amount_cents: 1000,
      created_at: Time.current,
      pending_disbursement: true
    )
  end

  describe "#create" do
    let(:valid_attributes) do
      {
        merchant_id: merchant.id,
        amount_cents: 1000,
        fees_amount_cents: 10,
        orders: [ order ],
        disbursed_at: Time.current.utc
      }
    end

    it "creates a disbursement record" do
      expect {
        repository.create(valid_attributes)
      }.to change(Infrastructure::Persistence::ActiveRecord::Models::Disbursement, :count).by(1)
    end

    it "returns a domain entity" do
      result = repository.create(valid_attributes)
      expect(result).to be_a(Domain::Disbursements::Entities::Disbursement)
    end

    it "sets the correct attributes" do
      result = repository.create(valid_attributes)
      expect(result.merchant_id).to eq(merchant.id)
      expect(result.amount_cents).to eq(1000)
      expect(result.fees_amount_cents).to eq(10)
    end

    it "associates orders with the disbursement" do
      result = repository.create(valid_attributes)
      disbursement = Infrastructure::Persistence::ActiveRecord::Models::Disbursement.find(result.id)
      expect(disbursement.orders).to include(order)
    end

    it "updates associated orders' pending_disbursement status" do
      repository.create(valid_attributes)
      expect(order.reload.pending_disbursement).to be false
    end

    context "with multiple orders" do
      let(:order2) do
        Infrastructure::Persistence::ActiveRecord::Models::Order.create!(
          id: "order_2",
          merchant_reference: merchant.reference,
          amount_cents: 2000,
          created_at: Time.current,
          pending_disbursement: true
        )
      end

      let(:valid_attributes) do
        {
          merchant_id: merchant.id,
          amount_cents: 3000,
          fees_amount_cents: 20,
          orders: [ order, order2 ],
          disbursed_at: Time.current.utc
        }
      end

      it "updates all orders' pending_disbursement status" do
        repository.create(valid_attributes)
        expect(order.reload.pending_disbursement).to be false
        expect(order2.reload.pending_disbursement).to be false
      end
    end

    context "when creation fails" do
      let(:invalid_attributes) { valid_attributes.merge(merchant_id: nil) }

      it "raises an error" do
        expect {
          repository.create(invalid_attributes)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "#find" do
    let!(:disbursement) do
      Infrastructure::Persistence::ActiveRecord::Models::Disbursement.create!(
        merchant_id: merchant.id,
        amount_cents: 1000,
        fees_amount_cents: 10,
        disbursed_at: Time.current.utc
      )
    end

    it "returns a domain entity" do
      result = repository.find(disbursement.id)
      expect(result).to be_a(Domain::Disbursements::Entities::Disbursement)
    end

    it "returns the correct disbursement" do
      result = repository.find(disbursement.id)
      expect(result.id).to eq(disbursement.id)
      expect(result.merchant_id).to eq(merchant.id)
      expect(result.amount_cents).to eq(1000)
      expect(result.fees_amount_cents).to eq(10)
    end

    context "when disbursement doesn't exist" do
      it "raises an error" do
        expect {
          repository.find(-1)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
