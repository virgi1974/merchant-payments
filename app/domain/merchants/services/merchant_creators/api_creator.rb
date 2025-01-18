# app/domain/merchants/services/merchant_creators/api_creator.rb
module Domain
  module Merchants
    module Services
      module MerchantCreators
        class ApiCreator < BaseCreator
          def call
            # API-specific validations/transformations
            normalized_data = normalize_merchant_data
            validate_api_specific_fields!
            create_merchant(normalized_data)
          end

          private

          def validate_api_specific_fields!
            # API-specific validation logic
          end

          def create_merchant(data)
            record = Infrastructure::Persistence::ActiveRecord::Merchant.create!(data)
            Domain::Merchants::Merchant.new(record.attributes)
          end
        end
      end
    end
  end
end
