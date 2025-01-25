module Domain
  module Disbursements
    module Services
      class DisbursementCalculator
        def initialize(date = Date.current)
          @date = date
          @repository = Repositories::DisbursementRepository.new
          @eligible_merchants_query = Queries::DisbursableMerchantsQuery.new(date)
        end

        def create_disbursements
          results = { successful: [], failed: [] }

          @eligible_merchants_query.call_in_batches.each do |merchant|
            process_merchant_disbursement(merchant, results)
          end

          results
        end

        private

        def fetch_eligible_merchants_in_batches
          @eligible_merchants_query.call_in_batches
        rescue StandardError => e
          Rails.logger.error("Failed to fetch eligible merchants: #{e.message}")
          []
        end

        def process_merchant_disbursement(merchant, results)
          ActiveRecord::Base.transaction do
            calculator = build_frequency_based_calculator(merchant)
            disbursement = calculator.calculate_and_create
            results[:successful] << disbursement if disbursement
          end
        rescue StandardError => e
          results[:failed] << build_error_info(merchant, e)
          log_error(merchant, e)
        end

        def build_error_info(merchant, error)
          {
            merchant_id: merchant.id,
            error: error.message,
            backtrace: error.backtrace.first(5)
          }
        end

        def log_error(merchant, error)
          Rails.logger.error("Failed to create disbursement for merchant #{merchant.id}: #{error.message}")
        end

        def build_frequency_based_calculator(merchant)
          Domain::Disbursements::Factories::FrequencyBasedFactory.create(
            merchant.disbursement_frequency,
            merchant,
            @date,
            @repository
          )
        end
      end
    end
  end
end
