module Domain
  module Fees
    module Repositories
      class MonthlyFeeRepository
        DISBURSEMENT_MODEL = Infrastructure::Persistence::ActiveRecord::Models::Disbursement
        MONTHLY_FEE_ADJUSTMENT_MODEL = Infrastructure::Persistence::ActiveRecord::Models::MonthlyFeeAdjustment


        def total_fees_for_month(merchant, month, year)
          start_date = Date.new(year, month, 1)
          end_date = start_date.end_of_month

          disbursements = DISBURSEMENT_MODEL
            .where(merchant: merchant)
            .where(created_at: start_date..end_date)

          return nil unless disbursements.exists?

          disbursements.sum(:fees_amount_cents)
        end

        def create_monthly_adjustment(merchant:, amount:, month:, year:)
          MONTHLY_FEE_ADJUSTMENT_MODEL.create!(
            merchant: merchant,
            amount_cents: amount,
            month: month,
            year: year
          )
        end

        def adjustment_exists?(merchant, month, year)
          MONTHLY_FEE_ADJUSTMENT_MODEL
            .exists?(merchant: merchant, month: month, year: year)
        end

        def count_for_year(year)
          MONTHLY_FEE_ADJUSTMENT_MODEL.count_for_year(year)
        end

        def sum_amount_for_year(year)
          MONTHLY_FEE_ADJUSTMENT_MODEL.total_amount_for_year(year)
        end
      end
    end
  end
end
