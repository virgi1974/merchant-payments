require "rails_helper"

module Domain
  module Disbursements
    module Queries
      RSpec.describe DisbursableMerchantsQuery do
        let(:reference_date) { Date.new(2024, 1, 15) } # Tuesday
        let(:query) { described_class.new(reference_date) }
        let(:repository) { instance_double(Domain::Merchants::Repositories::MerchantRepository) }
        let(:disbursable_merchant_class) { Domain::Merchants::Entities::DisbursableMerchant }

        before do
          allow(Domain::Merchants::Repositories::MerchantRepository).to receive(:new).and_return(repository)
        end

        describe "#call_in_batches" do
          context "with weekly merchants" do
            let(:weekly_merchant_entity) do
              disbursable_merchant_class.new(
                reference: "weekly_matching",
                disbursement_frequency: "weekly",
                live_on: "2024-01-08",
                email: "weekly@example.com",
                minimum_monthly_fee_cents: 2900
              )
            end

            it "returns matching weekly merchants in batches" do
              allow(repository).to receive(:find_disbursable_merchants_in_batches)
                .with(reference_date)
                .and_return([ weekly_merchant_entity ].to_enum)

              result = query.call_in_batches
              expect(result.to_a.map(&:reference)).to contain_exactly("weekly_matching")
              expect(result.to_a.first).to be_a(disbursable_merchant_class)
            end
          end

          context "with daily merchants" do
            let(:daily_merchant_entity) do
              disbursable_merchant_class.new(
                reference: "daily_merchant",
                disbursement_frequency: "daily",
                live_on: reference_date,
                email: "daily@example.com",
                minimum_monthly_fee_cents: 2900
              )
            end

            it "returns daily merchants in batches" do
              allow(repository).to receive(:find_disbursable_merchants_in_batches)
                .with(reference_date)
                .and_return([ daily_merchant_entity ].to_enum)

              result = query.call_in_batches
              expect(result.to_a.map(&:reference)).to contain_exactly("daily_merchant")
              expect(result.to_a.first).to be_a(disbursable_merchant_class)
            end
          end

          context "with no merchants" do
            it "returns empty enumerable" do
              allow(repository).to receive(:find_disbursable_merchants_in_batches)
                .with(reference_date)
                .and_return([].to_enum)

              result = query.call_in_batches
              expect(result.to_a).to be_empty
            end
          end

          context "when repository raises error" do
            before do
              allow(repository).to receive(:find_disbursable_merchants_in_batches)
                .and_raise(StandardError.new("Database connection failed"))
            end

            it "logs error and returns empty enumerable" do
              expect(Rails.logger).to receive(:error).with(/Failed to fetch eligible merchants/)

              result = query.call_in_batches
              expect(result).to be_a(Enumerator)
              expect(result.to_a).to be_empty
            end
          end
        end
      end
    end
  end
end
