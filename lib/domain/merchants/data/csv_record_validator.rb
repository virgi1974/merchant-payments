module Domain
  module Merchants
    module Data
      class CsvRecordValidator < Dry::Struct
        include Domain::Shared::Types
        Types = Domain::Shared::Types

        attribute :id, Types::UUID
        attribute :reference, Types::String
        attribute :email, Types::Email
        attribute :live_on, Types::Date
        attribute :disbursement_frequency, Types::DisbursementFrequency
        attribute :minimum_monthly_fee, Types::PositiveDecimal

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
            reference: row["reference"],
            email: row["email"],
            live_on: parse_date(row["live_on"]),
            disbursement_frequency: row["disbursement_frequency"],
            minimum_monthly_fee: parse_decimal(row["minimum_monthly_fee"])
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

        def parse_date(date_string)
          ::Date.parse(date_string)
        rescue Date::Error => e
          raise Dry::Struct::Error, "Invalid date format for live_on: #{date_string}"
        end

        def parse_decimal(decimal_string)
          BigDecimal(decimal_string.to_s)
        rescue ArgumentError => e
          raise Dry::Struct::Error, "Invalid decimal format for minimum_monthly_fee: #{decimal_string}"
        end
      end
    end
  end
end
