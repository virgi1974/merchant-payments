require "rails_helper"

module Domain
  module Disbursements
    module Entities
      RSpec.describe Disbursement do
        let(:order) { instance_double("Order", amount_cents: 1000) }

        let(:valid_attributes) do
          {
            id: 1,
            merchant_id: 123,
            amount_cents: 1000,
            fees_amount_cents: 10,
            orders: [ order ]
          }
        end

        describe "#initialize" do
          it "creates a disbursement with valid attributes" do
            disbursement = described_class.new(valid_attributes)

            expect(disbursement.id).to eq(1)
            expect(disbursement.merchant_id).to eq(123)
            expect(disbursement.amount_cents).to eq(1000)
            expect(disbursement.fees_amount_cents).to eq(10)
            expect(disbursement.orders).to eq([ order ])
          end

          it "defaults orders to empty array when not provided" do
            disbursement = described_class.new(valid_attributes.except(:orders))
            expect(disbursement.orders).to eq([])
          end

          it "allows nil values for optional attributes" do
            disbursement = described_class.new(merchant_id: 123)

            expect(disbursement.id).to be_nil
            expect(disbursement.amount_cents).to be_nil
            expect(disbursement.fees_amount_cents).to be_nil
            expect(disbursement.orders).to eq([])
          end
        end
      end
    end
  end
end
