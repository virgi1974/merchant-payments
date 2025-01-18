module Infrastructure
  module Persistence
    module ActiveRecord
      class Merchant < ApplicationRecord
        include HasUuid

        enum disbursement_frequency: {
          weekly: 0,
          daily: 1
        }

        monetize :minimum_monthly_fee_cents

        validates :id, presence: true, uniqueness: true
        validates :reference, presence: true, uniqueness: true
        validates :email, presence: true
        validates :live_on, presence: true
        validates :disbursement_frequency, presence: true

        # TODO: Add these relationships later
        # has_many :orders, foreign_key: :merchant_reference, primary_key: :reference
        # has_many :disbursements, foreign_key: :merchant_reference, primary_key: :reference
        # has_many :monthly_fees, foreign_key: :merchant_reference, primary_key: :reference
      end
    end
  end
end
