module Infrastructure
  module Persistence
    module ActiveRecord
      module Models
        class Order < ApplicationRecord
          belongs_to :merchant,
                    class_name: "Infrastructure::Persistence::ActiveRecord::Models::Merchant",
                    foreign_key: :merchant_reference,
                    primary_key: :reference

          monetize :amount_cents

          validates :amount_cents, presence: true, numericality: { greater_than: 0 }
          validates :created_at, presence: true
        end
      end
    end
  end
end
