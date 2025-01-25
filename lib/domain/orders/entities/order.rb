# app/domain/merchants/entities/merchant.rb
module Domain
  module Orders
    module Entities
      class Order
        attr_reader :id, :merchant_reference, :amount_cents, :amount_currency, :created_at

        def initialize(attributes = {})
          @id = attributes[:id]
          @merchant_reference = attributes[:merchant_reference]
          @amount_cents = attributes[:amount_cents]
          @amount_currency = attributes[:amount_currency]
          @created_at = attributes[:created_at]
        end
      end
    end
  end
end
