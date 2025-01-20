module Domain
  module Orders
    module Data
      class CsvRecordValidator < Dry::Struct
        include Domain::Shared::Types
        Types = Domain::Shared::Types

        attribute :id, Types::HexId
        attribute :merchant_reference, Types::String
        attribute :amount, Types::PositiveDecimal
        attribute :created_at, Types::Date

        class << self
          def call(separator)
            new_instance = allocate
            new_instance.send(:initialize_separator, separator)
            new_instance
          end
        end

        def process_row(row)
          self.class.new(
            id: row["id"],
            merchant_reference: row["merchant_reference"],
            amount: row["amount"],
            created_at: row["created_at"]
          )
        rescue ArgumentError, Dry::Struct::Error => e
          raise Dry::Struct::Error, "#{e.message} - Row: #{row.to_h}"
        end

        private

        attr_reader :separator

        def initialize_separator(sep)
          @separator = sep
          self
        end
      end
    end
  end
end
