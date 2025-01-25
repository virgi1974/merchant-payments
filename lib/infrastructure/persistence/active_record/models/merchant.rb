module Infrastructure
  module Persistence
    module ActiveRecord
      module Models
        class Merchant < ApplicationRecord
          # 1. Includes/Extends (mixins)
          include Infrastructure::Persistence::ActiveRecord::Concerns::HasUuid

          # 2. Constants (if any)

          # 3. Attributes/Enums/Monetize
          enum :disbursement_frequency, Domain::Merchants::ValueObjects::DisbursementFrequency::FREQUENCIES
          monetize :minimum_monthly_fee_cents

          # 4. Associations
          has_many :orders,
                   class_name: "Infrastructure::Persistence::ActiveRecord::Models::Order",
                   foreign_key: :merchant_reference,
                   primary_key: :reference
          has_many :disbursements,
                   class_name: "Infrastructure::Persistence::ActiveRecord::Models::Disbursement"
          # has_many :monthly_fees, foreign_key: :merchant_reference, primary_key: :reference

          # 5. Validations
          validates :id, presence: true, uniqueness: true
          validates :reference, presence: true, uniqueness: true
          validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
          validates :live_on, presence: true
          validates :disbursement_frequency, presence: true
          validates :minimum_monthly_fee_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }

          # 6. Callbacks (if any)

          # 7. Scopes (if any)
          scope :with_frequency, ->(frequency) { where(disbursement_frequency: frequency) }
          scope :matching_weekday, ->(date) {
            where("CAST(strftime('%w', live_on) AS INTEGER) = ?", date.wday)
          }
          scope :with_pending_orders, ->(start_time:, end_time:) {
            includes(:orders)
              .where(orders: {
                pending_disbursement: true,
                created_at: start_time..end_time
              })
          }

          # 8. Class methods

          # 9. Instance methods
        end
      end
    end
  end
end
