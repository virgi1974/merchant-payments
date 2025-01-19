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
            @merchant_data = merchant_data # dry-struct with CSV data
          end

          def call
            validate_merchant_data
            normalized_data = normalize_merchant_data
            create_merchant(normalized_data)
          end

          private

          attr_reader :merchant_data

          def validate_merchant_data
            validate_disbursement_frequency
            validate_minimum_monthly_fee
          end

          def validate_disbursement_frequency
            unless ValueObjects::DisbursementFrequency.valid?(merchant_data.disbursement_frequency)
              raise Domain::Merchants::Errors::InvalidDisbursementFrequency
            end
          end

          def validate_minimum_monthly_fee
            return if merchant_data.minimum_monthly_fee >= 0

            raise Domain::Merchants::Errors::InvalidMinimumMonthlyFee
          end

          def normalize_merchant_data
            {
              id: merchant_data.id,
              reference: merchant_data.reference,
              email: merchant_data.email,
              disbursement_frequency: ValueObjects::DisbursementFrequency.normalize(merchant_data.disbursement_frequency),
              minimum_monthly_fee_cents: (merchant_data.minimum_monthly_fee * 100).to_i, # Convert to cents
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
