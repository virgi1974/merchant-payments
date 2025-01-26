module Domain
  module Fees
    module Services
      class MonthlyFeeTracker
        def initialize(repository = Repositories::MonthlyFeeRepository.new)
          @repository = repository
        end

        def process_merchant(merchant, month, year)
          return if @repository.adjustment_exists?(merchant, month, year)

          total_fees = calculate_monthly_fees(merchant, month, year)
          minimum_fee = merchant.minimum_monthly_fee_cents
          fee_difference = minimum_fee - total_fees

          create_adjustment(merchant, fee_difference, month, year) if fee_difference.positive?
        end

        private

        def calculate_monthly_fees(merchant, month, year)
          @repository.total_fees_for_month(merchant, month, year)
        end

        def create_adjustment(merchant, amount, month, year)
          @repository.create_monthly_adjustment(
            merchant: merchant,
            amount: amount,
            month: month,
            year: year
          )
        end
      end
    end
  end
end
