require "rails_helper"

module Domain
  module Merchants
    module Entities
      RSpec.describe DisbursableMerchant do
        describe "#initialize" do
          context "with daily frequency" do
            let(:attributes) do
              {
                id: "123",
                reference: "merchant_ref",
                disbursement_frequency: "daily"
              }
            end

            it "creates entity with daily frequency" do
              merchant = described_class.new(attributes)

              expect(merchant.id).to eq("123")
              expect(merchant.reference).to eq("merchant_ref")
              expect(merchant.disbursement_frequency).to eq("daily")
            end
          end

          context "with weekly frequency" do
            let(:attributes) do
              {
                id: "456",
                reference: "weekly_merchant",
                disbursement_frequency: "weekly"
              }
            end

            it "creates entity with weekly frequency" do
              merchant = described_class.new(attributes)

              expect(merchant.disbursement_frequency).to eq("weekly")
            end
          end

          it "only exposes read-only attributes" do
            merchant = described_class.new(
              id: "123",
              reference: "merchant_ref",
              disbursement_frequency: "daily"
            )

            expect(merchant).not_to respond_to(:id=)
            expect(merchant).not_to respond_to(:reference=)
            expect(merchant).not_to respond_to(:disbursement_frequency=)
          end
        end
      end
    end
  end
end
