module Domain
  module Disbursements
    module Services
      module Calculators
        class Base
          def initialize(merchant, date, repository)
            @merchant = merchant
            @date = date
            @repository = repository
            @fee_calculator = FeeCalculator.new
            @orders_query = Queries::PendingOrdersQuery.new(date)
          end

          def calculate_and_create
            orders = fetch_orders
            # binding.break
            return if orders.empty?

            create_disbursement(orders)
          rescue Errors::ValidationError => e
            Rails.logger.error("Validation failed for merchant #{@merchant.id}: #{e.message}")
            nil
          end

          protected

          def fetch_orders
            raise NotImplementedError, "#{self.class} must implement #fetch_orders"
          end

          private

          def create_disbursement(orders)
            attributes = build_disbursement_attributes(orders)

            validator = Data::Validator.new(attributes)
            raise Errors::ValidationError, validator.errors.full_messages unless validator.valid?

            @repository.create(attributes)
          end

          def build_disbursement_attributes(orders)
            {
              merchant_id: @merchant.id,
              amount_cents: orders.sum(&:amount_cents),
              fees_amount_cents: @fee_calculator.calculate_total_fees(orders),
              orders: orders,
              disbursed_at: Time.current.utc
            }
          end
        end
      end
    end
  end
end
