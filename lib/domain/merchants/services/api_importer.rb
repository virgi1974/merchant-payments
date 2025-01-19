module Domain
  module Merchants
    module Services
      class ApiImporter
        API_CREATOR = Domain::Merchants::Services::MerchantCreators::ApiCreator
        API_RECORD_VALIDATOR = Domain::Merchants::Data::ApiRecordValidator

        def self.call(params)
          new(params).call
        end

        def initialize(params)
          @params = params.symbolize_keys
        end

        def call
          Rails.logger.info "Starting merchant creation via API at #{Time.current}"

          ActiveRecord::Base.transaction do
            merchant = import_merchant
            Rails.logger.info "Successfully created merchant with ID: #{merchant.id}"
            merchant
          end
        rescue StandardError => e
          Rails.logger.error "Failed to create merchant: #{e.message}"
          raise
        end

        private

        attr_reader :params

        def import_merchant
          merchant_data = API_RECORD_VALIDATOR.call(params)
          API_CREATOR.call(merchant_data)
        rescue Dry::Struct::Error => e
          Rails.logger.error "Invalid data: #{e.message}"
          raise Domain::Merchants::Errors::ValidationError, e.message
        rescue StandardError => e
          Rails.logger.error "Failed to create merchant: #{e.message}"
          raise
        end
      end
    end
  end
end
