module Infrastructure
  module Persistence
    module ActiveRecord
      module Models
        class MonthlyFeeAdjustment < ApplicationRecord
          # 1. Includes/Extends

          # 2. Constants (if any)

          # 3. Attributes/Enums/Monetize
          monetize :amount_cents

          # 4. Associations
          belongs_to :merchant,
                     class_name: "Infrastructure::Persistence::ActiveRecord::Models::Merchant"

          # 5. Validations
          validates :amount_cents, presence: true, numericality: { greater_than: 0 }
          validates :month, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 12 }
          validates :year, presence: true, numericality: { only_integer: true }
          validates :merchant, presence: true
          validates :month, uniqueness: { scope: [ :merchant_id, :year ],
                                        message: "already has an adjustment for this month/year" }

          # 6. Callbacks (if any)

          # 7. Scopes (if any)
          scope :for_month_and_year, ->(month, year) { where(month: month, year: year) }
          scope :for_year, ->(year) { where(year: year) }
          scope :total_amount_for_year, ->(year) { for_year(year).sum(:amount_cents) }
          scope :count_for_year, ->(year) { for_year(year).count }

          # 8. Class methods

          # 9. Instance methods
        end
      end
    end
  end
end
