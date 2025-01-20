module Domain
  module Orders
    module Services
      module OrderCreators
        class BaseCreator
          class << self
            def call(input)
              raise NotImplementedError, "#{name} is an abstract class" if self == BaseCreator
              new(input).call
            end
          end

          def initialize(input)
            raise NotImplementedError, "#{self.class.name} is an abstract class" if instance_of?(BaseCreator)
            @order_data = input
          end

          def call
            validate_order_data
            normalized_data = normalize_order_data
            create_order(normalized_data)
          end

          protected

          attr_reader :order_data

          private

          def validate_order_data
            validate_amount
          end

          # def validate_merchant_existance?
          #   unless ValueObjects::DisbursementFrequency.valid?(order_data.disbursement_frequency)
          #     raise Domain::Orders::Errors::InvalidDisbursementFrequency
          #   end
          # end

          def validate_amount
            return if Money.from_amount(order_data.amount) >= Money.new(0)
            raise Domain::Orders::Errors::InvalidMinimumAmount
          end

          def normalize_order_data
            {
              id: order_data.id,
              merchant_reference: order_data.merchant_reference,
              amount_cents: Money.from_amount(order_data.amount).cents,
              amount_currency: "EUR",
              created_at: order_data.created_at
            }
          end

          def create_order(data)
            order_repository.create(data)
          end

          def order_repository
            @order_repository ||= Domain::Orders::Repositories::OrderRepository.new
          end
        end
      end
    end
  end
end
