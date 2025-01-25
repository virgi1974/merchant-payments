module Domain
  module Disbursements
    module Data
      class Validator
        include ActiveModel::Validations

        attr_reader :merchant_id, :amount_cents, :fees_amount_cents, :orders

        validates :merchant_id, presence: true
        validates :amount_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
        validates :fees_amount_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
        validates :orders, presence: true
        validate :fees_less_than_amount
        validate :orders_total_matches_amount

        def initialize(attributes = {})
          @merchant_id = attributes[:merchant_id]
          @amount_cents = attributes[:amount_cents]
          @fees_amount_cents = attributes[:fees_amount_cents]
          @orders = attributes[:orders]
        end

        private

        def fees_less_than_amount
          return unless amount_cents && fees_amount_cents

          if fees_amount_cents > amount_cents
            errors.add(:fees_amount_cents, "cannot be greater than total amount")
          end
        end

        def orders_total_matches_amount
          return unless orders.present? && amount_cents

          total = orders.sum(&:amount_cents)
          if total != amount_cents
            errors.add(:amount_cents, "must match the sum of order amounts")
          end
        end
      end
    end
  end
end
