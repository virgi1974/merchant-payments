module Domain
  module Disbursements
    module Entities
      class Disbursement
        attr_reader :id, :merchant_id, :amount_cents, :fees_amount_cents, :orders

        def initialize(attributes = {})
          @id = attributes[:id]
          @merchant_id = attributes[:merchant_id]
          @amount_cents = attributes[:amount_cents]
          @fees_amount_cents = attributes[:fees_amount_cents]
          @orders = attributes[:orders] || []
        end
      end
    end
  end
end
