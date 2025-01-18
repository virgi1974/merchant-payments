# app/domain/merchants/services/merchant_creators/csv_creator.rb
module Domain
  module Merchants
    module Services
      module MerchantCreators
        class CsvCreator < BaseCreator
          def self.call(merchant_data)
            new(merchant_data).call
          end

          def initialize(merchant_data)
            @merchant_data = merchant_data
          end

          def call
            # CSV-specific validations/transformations
            normalized_data = normalize_merchant_data
            create_merchant(normalized_data)
          end

          private

          attr_reader :merchant_data

          def create_merchant(data)
            record = Infrastructure::Persistence::ActiveRecord::Merchant.create!(data)
            Domain::Merchants::Merchant.new(record.attributes)
          end

          def create_merchant_record(data)
            Infrastructure::Persistence::ActiveRecord::Merchant.create!(data)
          end

          def build_domain_entity(record)
            Domain::Merchants::Merchant.new(record.attributes)
          end
        end
      end
    end
  end
end
