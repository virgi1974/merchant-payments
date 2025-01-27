module Domain
  module Disbursements
    module Queries
      class DisbursableMerchantsQuery
        def initialize(date)
          @date = date
          @repository = Domain::Merchants::Repositories::MerchantRepository.new
        end

        def call_in_batches
          @repository.find_disbursable_merchants_in_batches(@date)
        rescue StandardError => e
          Rails.logger.error("Failed to fetch eligible merchants: #{e.message}")
          [].to_enum # Return empty enumerable
        end

        def call_historical_in_batches
          @repository.find_historical_disbursable_merchants_in_batches(@date)
        rescue StandardError => e
          Rails.logger.error("Failed to fetch eligible merchants: #{e.message}")
          [].to_enum # Return empty enumerable
        end
      end
    end
  end
end
