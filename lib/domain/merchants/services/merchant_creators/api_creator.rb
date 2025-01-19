# app/domain/merchants/services/merchant_creators/api_creator.rb
module Domain
  module Merchants
    module Services
      module MerchantCreators
        class ApiCreator < BaseCreator
          def self.call(merchant_data)
            new(merchant_data).call
          end

          def initialize(merchant_data)
            @merchant_data = merchant_data
          end

          def call
            normalized_data = normalize_merchant_data
            create_merchant(normalized_data)
          end

          private

          attr_reader :merchant_data

          def normalize_merchant_data
            {
              id: merchant_data.id,
              reference: merchant_data.reference,
              email: merchant_data.email,
              disbursement_frequency: ValueObjects::DisbursementFrequency.normalize(merchant_data.disbursement_frequency),
              minimum_monthly_fee_cents: (merchant_data.minimum_monthly_fee * 100).to_i,
              live_on: merchant_data.live_on
            }
          end

          def create_merchant(data)
            merchant_repository.create(data)
          end

          def merchant_repository
            @merchant_repository ||= Domain::Merchants::Repositories::MerchantRepository.new
          end
        end
      end
    end
  end
end
