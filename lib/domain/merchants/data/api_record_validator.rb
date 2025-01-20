module Domain
  module Merchants
    module Data
      class ApiRecordValidator < Dry::Struct
        include Domain::Shared::Types
        Types = Domain::Shared::Types

        attribute :id, Types::UUID.optional.default(nil)
        attribute :reference, Types::String
        attribute :email, Types::Email
        attribute :live_on, Types::Date
        attribute :disbursement_frequency, Types::DisbursementFrequency
        attribute :minimum_monthly_fee, Types::PositiveDecimal

        class << self
          def call(params)
            new_instance = allocate
            new_instance.process_params(params)
          end
        end

        def process_params(params)
          self.class.new(
            id: nil,
            reference: params[:reference],
            email: params[:email],
            live_on: params[:live_on],
            disbursement_frequency: params[:disbursement_frequency],
            minimum_monthly_fee: params[:minimum_monthly_fee]
          )
        rescue Dry::Struct::Error => e
          raise Dry::Struct::Error, "#{e.message} - Params: #{params}"
        end
      end
    end
  end
end
