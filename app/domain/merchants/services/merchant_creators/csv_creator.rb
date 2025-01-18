# app/domain/merchants/services/merchant_creators/csv_creator.rb
module Domain
  module Merchants
    module Services
      module MerchantCreators
        class CsvCreator < Domain::Merchants::Services::MerchantCreators::BaseCreator
          # Domain::Merchants::Services::MerchantCreators::BaseCreator
          def call
            binding.break
            # CSV-specific validations/transformations
            normalized_data = normalize_merchant_data
            create_merchant(normalized_data)
          end

          private

          def create_merchant(data)
            record = Infrastructure::Persistence::ActiveRecord::Merchant.create!(data)
            Domain::Merchants::Merchant.new(record.attributes)
          end
        end
      end
    end
  end
end
