# app/domain/merchants/entities/merchant.rb
module Domain
  module Merchants
    module Entities
      class Merchant
        attr_reader :id, :reference, :email, :live_on, :disbursement_frequency, :minimum_monthly_fee, :orders

        def initialize(attributes = {})
          @id = attributes[:id]
          @reference = attributes[:reference]
          @email = attributes[:email]
          @live_on = attributes[:live_on]
          @disbursement_frequency = attributes[:disbursement_frequency]
          @minimum_monthly_fee = Money.new(attributes[:minimum_monthly_fee_cents])
          @orders = attributes[:orders] || []
        end

        def calculate_monthly_fee(month_fees)
          return Money.new(0) if month_fees >= minimum_monthly_fee
          minimum_monthly_fee - month_fees
        end
      end
    end
  end
end
