module Domain
  module Orders
    module Services
      class ApiImporter
        API_CREATOR = Domain::Orders::Services::OrderCreators::ApiCreator
        API_RECORD_VALIDATOR = Domain::Orders::Data::ApiRecordValidator

        def self.call(params)
          new(params).call
        end

        def initialize(params)
          @params = params.symbolize_keys
        end

        def call
          Rails.logger.info "Starting order creation via API at #{Time.current}"

          ActiveRecord::Base.transaction do
            merchant = import_order
            Rails.logger.info "Successfully created order with ID: #{merchant.id}"
            merchant
          end
        rescue StandardError => e
          Rails.logger.error "Failed to create order: #{e.message}"
          raise e.class
        end

        private

        attr_reader :params

        def import_order
          order_data = API_RECORD_VALIDATOR.call(params)
          API_CREATOR.call(order_data)
        rescue Dry::Struct::Error => e
          Rails.logger.error "Invalid data: #{e.message}"
          raise Domain::Orders::Errors::ValidationError, e.message
        rescue StandardError => e
          Rails.logger.error "Failed to create order: #{e.message}"
          raise
        end
      end
    end
  end
end
