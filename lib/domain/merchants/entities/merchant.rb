# app/domain/merchants/entities/merchant.rb
module Domain
  module Merchants
    module Entities
      class Merchant
        attr_reader :id, :reference, :email, :live_on, :disbursement_frequency, :minimum_monthly_fee

        def initialize(attributes = {})
          @id = attributes[:id]
          @reference = attributes[:reference]
          @email = attributes[:email]
          @live_on = attributes[:live_on]
          @disbursement_frequency = attributes[:disbursement_frequency]
          @minimum_monthly_fee = Money.new(attributes[:minimum_monthly_fee_cents])
        end

        def ready_for_disbursement?(date)
          return true if daily?
          return weekly_disbursement_day?(date) if weekly?
          false
        end

        def calculate_monthly_fee(month_fees)
          return Money.new(0) if month_fees >= minimum_monthly_fee
          minimum_monthly_fee - month_fees
        end

        private

        def daily?
          disbursement_frequency == :daily
        end

        def weekly?
          disbursement_frequency == :weekly
        end

        def weekly_disbursement_day?(date)
          date.wday == live_on.wday
        end
      end
    end
  end
end
