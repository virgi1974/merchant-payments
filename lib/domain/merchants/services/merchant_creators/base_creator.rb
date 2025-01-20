# app/domain/merchants/services/merchant_creators/base.rb
module Domain
  module Merchants
    module Services
      module MerchantCreators
        class BaseCreator
          class << self
            def call(input)
              raise NotImplementedError, "#{name} is an abstract class" if self == BaseCreator
              new(input).call
            end
          end

          def initialize(input)
            raise NotImplementedError, "#{self.class.name} is an abstract class" if instance_of?(BaseCreator)
            @merchant_data = input
          end

          def call
            validate_merchant_data
            normalized_data = normalize_merchant_data
            create_merchant(normalized_data)
          end

          protected

          attr_reader :merchant_data

          private

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
            return if Money.from_amount(merchant_data.minimum_monthly_fee) >= Money.new(0)
            raise Domain::Merchants::Errors::InvalidMinimumMonthlyFee
          end

          def normalize_merchant_data
            {
              id: merchant_data.id,
              reference: merchant_data.reference,
              email: merchant_data.email,
              disbursement_frequency: ValueObjects::DisbursementFrequency.normalize(merchant_data.disbursement_frequency),
              minimum_monthly_fee_cents: Money.from_amount(merchant_data.minimum_monthly_fee).cents,
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
