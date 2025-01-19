module Infrastructure
  module Persistence
    module ActiveRecord
      module Models
        class Merchant < ApplicationRecord
          include Infrastructure::Persistence::ActiveRecord::Concerns::HasUuid

          enum :disbursement_frequency, Domain::Merchants::ValueObjects::DisbursementFrequency::FREQUENCIES

          monetize :minimum_monthly_fee_cents

          validates :id, presence: true, uniqueness: true
          validates :reference, presence: true, uniqueness: true
          validates :email, presence: true
          validates :live_on, presence: true
          validates :disbursement_frequency, presence: true
          validates :minimum_monthly_fee_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }

          # TODO: Add these relationships later
          # has_many :orders, foreign_key: :merchant_reference, primary_key: :reference
          # has_many :disbursements, foreign_key: :merchant_reference, primary_key: :reference
          # has_many :monthly_fees, foreign_key: :merchant_reference, primary_key: :reference
        end
      end
    end
  end
end
