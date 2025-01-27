module Infrastructure
  module Persistence
    module ActiveRecord
      module Models
        class Disbursement < ApplicationRecord
          # 1. Includes/Extends
          include Infrastructure::Persistence::ActiveRecord::Concerns::HasDisbursementUuid

          # 2. Constants (if any)

          # 3. Attributes/Enums/Monetize
          monetize :amount_cents
          monetize :fees_amount_cents

          # 4. Associations
          belongs_to :merchant,
                    class_name: "Infrastructure::Persistence::ActiveRecord::Models::Merchant"
          has_many :orders,
                   class_name: "Infrastructure::Persistence::ActiveRecord::Models::Order"

          # 5. Validations
          # validates :disbursed_at, presence: true, if: :completed?  # For future status implementation
          validates :amount_cents, presence: true, numericality: { greater_than: 0 }
          validates :fees_amount_cents, presence: true, numericality: { greater_than: 0 }

          # 6. Callbacks (if any)

          # 7. Scopes (if any)
          scope :for_year, ->(year) { where("strftime('%Y', created_at) = ?", year.to_s) }
          scope :sum_amount_for_year, ->(year) { for_year(year).sum(:amount_cents) }
          scope :sum_fees_for_year, ->(year) { for_year(year).sum(:fees_amount_cents) }

          # 8. Class methods

          # 9. Instance methods
        end
      end
    end
  end
end
