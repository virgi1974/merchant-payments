module Domain
  module Orders
    module Data
      class ApiRecordValidator < Dry::Struct
        include Domain::Shared::Types
        Types = Domain::Shared::Types

        attribute :id, Types::HexId.optional.default(nil)
        attribute :merchant_reference, Types::String
        attribute :amount, Types::PositiveDecimal
        attribute :created_at, Types::Date

        class << self
          def call(params)
            new_instance = allocate
            new_instance.process_params(params)
          end
        end

        def process_params(params)
          self.class.new(
            id: nil,
            merchant_reference: params[:merchant_reference],
            amount: params[:amount],
            created_at: params[:created_at]
          )
        rescue Dry::Struct::Error => e
          raise Dry::Struct::Error, "#{e.message} - Params: #{params}"
        end
      end
    end
  end
end
