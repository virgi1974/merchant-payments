# app/domain/merchants/services/merchant_creators/base.rb
module Domain
  module Merchants
    module Services
      module MerchantCreators
        class BaseCreator
          def self.call(input)
            new(input).call
          end

          def initialize(input)
            @input = input
          end

          protected

          def normalize_merchant_data
            {
              # Common normalization logic
              disbursement_frequency: normalize_frequency(@input[:disbursement_frequency]),
              minimum_monthly_fee: normalize_amount(@input[:minimum_monthly_fee])
              # ... other common fields
            }
          end

          private

          def normalize_frequency(freq)
            freq.to_s.downcase.to_sym
          end

          def normalize_amount(amount)
            (BigDecimal(amount.to_s) * 100).to_i
          end
        end
      end
    end
  end
end
