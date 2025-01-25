module Domain
  module Merchants
    module Entities
      class DisbursableMerchant
        attr_reader :id, :reference, :disbursement_frequency, :live_on, :minimum_monthly_fee_cents

        def initialize(attributes)
          @id = attributes[:id]
          @reference = attributes[:reference]
          @disbursement_frequency = attributes[:disbursement_frequency]
          @live_on = attributes[:live_on]
          @minimum_monthly_fee_cents = attributes[:minimum_monthly_fee_cents]
        end
      end
    end
  end
end
