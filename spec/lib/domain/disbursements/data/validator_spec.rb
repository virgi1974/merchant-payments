require "rails_helper"

RSpec.describe Domain::Disbursements::Data::Validator do
  subject(:validator) { described_class.new(attributes) }

  let(:merchant) do
    Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
      reference: "merchant_1",
      email: "merchant@test.com",
      live_on: "2024-01-01",
      disbursement_frequency: "daily",
      minimum_monthly_fee_cents: 0
    )
  end

  let(:order1) { instance_double("Order", amount_cents: 1000) }
  let(:order2) { instance_double("Order", amount_cents: 2000) }
  let(:orders) { [ order1, order2 ] }

  let(:valid_attributes) do
    {
      merchant_id: merchant.id,
      amount_cents: 3000,
      fees_amount_cents: 30,
      orders: orders
    }
  end

  describe "validations" do
    context "when all attributes are valid" do
      let(:attributes) { valid_attributes }

      it "is valid" do
        expect(validator).to be_valid
      end
    end

    context "with missing required attributes" do
      [ :merchant_id, :amount_cents, :fees_amount_cents, :orders ].each do |attr|
        context "when #{attr} is missing" do
          let(:attributes) { valid_attributes.except(attr) }

          it "is invalid" do
            expect(validator).not_to be_valid
            expect(validator.errors[attr]).to include("can't be blank")
          end
        end
      end
    end

    context "with invalid amounts" do
      context "when amount_cents is negative" do
        let(:attributes) { valid_attributes.merge(amount_cents: -1000) }

        it "is invalid" do
          expect(validator).not_to be_valid
          expect(validator.errors[:amount_cents]).to include("must be greater than or equal to 0")
        end
      end

      context "when fees_amount_cents is negative" do
        let(:attributes) { valid_attributes.merge(fees_amount_cents: -10) }

        it "is invalid" do
          expect(validator).not_to be_valid
          expect(validator.errors[:fees_amount_cents]).to include("must be greater than or equal to 0")
        end
      end

      context "when fees are greater than amount" do
        let(:attributes) { valid_attributes.merge(fees_amount_cents: 4000) }

        it "is invalid" do
          expect(validator).not_to be_valid
          expect(validator.errors[:fees_amount_cents]).to include("cannot be greater than total amount")
        end
      end
    end

    context "with order amount mismatch" do
      context "when total order amounts don't match amount_cents" do
        let(:attributes) { valid_attributes.merge(amount_cents: 5000) }

        it "is invalid" do
          expect(validator).not_to be_valid
          expect(validator.errors[:amount_cents]).to include("must match the sum of order amounts")
        end
      end

      context "with empty orders array" do
        let(:attributes) { valid_attributes.merge(orders: []) }

        it "is invalid" do
          expect(validator).not_to be_valid
          expect(validator.errors[:orders]).to include("can't be blank")
        end
      end
    end

    context "with edge cases" do
      context "when amount and fees are zero" do
        let(:zero_order) { instance_double("Order", amount_cents: 0) }
        let(:attributes) do
          valid_attributes.merge(
            amount_cents: 0,
            fees_amount_cents: 0,
            orders: [ zero_order ]
          )
        end

        it "is valid" do
          expect(validator).to be_valid
        end
      end

      context "when fees equal amount" do
        let(:attributes) { valid_attributes.merge(fees_amount_cents: 3000) }

        it "is valid" do
          expect(validator).to be_valid
        end
      end

      context "when fees are greater than amount" do
        let(:attributes) { valid_attributes.merge(fees_amount_cents: 3001) }

        it "is invalid" do
          expect(validator).not_to be_valid
          expect(validator.errors[:fees_amount_cents]).to include("cannot be greater than total amount")
        end
      end
    end
  end
end
