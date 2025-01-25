module Infrastructure
  module Persistence
    module ActiveRecord
      module Models
        class Order < ApplicationRecord
          # 1. Includes/Extends
          include Infrastructure::Persistence::ActiveRecord::Concerns::HasHexUuid

          # 2. Constants (if any)
          VALID_CURRENCIES = %w[EUR].freeze

          # 3. Attributes/Enums/Monetize
          monetize :amount_cents

          # 4. Associations
          belongs_to :merchant,
                    class_name: "Infrastructure::Persistence::ActiveRecord::Models::Merchant",
                    foreign_key: :merchant_reference,
                    primary_key: :reference
          belongs_to :disbursement,
                    class_name: "Infrastructure::Persistence::ActiveRecord::Models::Disbursement",
                    optional: true

          # 5. Validations
          validates :merchant_reference, presence: true
          validates :amount_cents, presence: true, numericality: { greater_than: 0 }
          validates :created_at, presence: true
          validates :amount_currency, inclusion: { in: VALID_CURRENCIES }

          # 6. Callbacks (if any)

          # 7. Scopes (if any)
          scope :pending_disbursement, -> { where(pending_disbursement: true) }
          scope :by_creation, -> { order(created_at: :asc) }

          # 8. Class methods

          # 9. Instance methods
        end
      end
    end
  end
end
