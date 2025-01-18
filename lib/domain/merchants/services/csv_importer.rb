# app/domain/merchants/services/import_merchants.rb
require_relative "../services/csv_validator"
require_relative "../data/csv_record_validator"
require_relative "../services/merchant_creators/csv_creator"

module Domain
  module Merchants
    module Services
      class CsvImporter
        CSV_VALIDATOR = Domain::Merchants::Services::CsvValidator
        CSV_RECORD_VALIDATOR = Domain::Merchants::Data::CsvRecordValidator
        CSV_MERCHANT_CREATOR = Domain::Merchants::Services::MerchantCreators::CsvCreator

        def self.call(csv_path)
          new(csv_path).call
        end

        def initialize(csv_path)
          @csv_path = csv_path
          @failed_merchants = []
          @imported_count = 0
        end

        def call
          Rails.logger.info "Starting merchants import at #{Time.current}"

          validation = CSV_VALIDATOR.call(csv_path)

          unless validation[:valid]
            validation[:errors].each { |error| Rails.logger.error(error) }
            return
          end

          initialize_csv_record_validator(validation[:separator])
          csv = CSV.read(csv_path, headers: true, col_sep: validation[:separator])

          ActiveRecord::Base.transaction do
            csv.each.with_index(2) do |row, line|
              import_merchant(row, line)
            end

            handle_failures
          end

          Rails.logger.info "Successfully imported #{@imported_count} merchants"
        rescue CSV::MalformedCSVError => e
          Rails.logger.error "CSV parsing error: #{e.message}"
        rescue Errno::ENOENT => e
          Rails.logger.error "CSV file not found: #{e.message}"
        end

        private

        attr_reader :csv_path, :failed_merchants
        attr_accessor :imported_count

        def initialize_csv_record_validator(separator)
          @csv_record_validator = CSV_RECORD_VALIDATOR.call(separator)
        end

        def import_merchant(row, line)
          merchant_data = @csv_record_validator.process_row(row)
          CSV_MERCHANT_CREATOR.call(merchant_data)
          @imported_count += 1
        rescue Dry::Struct::Error => e
          failed_merchants << build_error(line, row, e)
          Rails.logger.error "Invalid data at line #{line}: #{e.message}"
        rescue StandardError => e
          failed_merchants << build_error(line, row, e)
          Rails.logger.error "Failed to import merchant at line #{line}: #{e.message}"
        end

        def handle_failures
          return unless failed_merchants.any?

          Rails.logger.error "Import failed for #{failed_merchants.count} merchants:"
          failed_merchants.each do |failure|
            Rails.logger.error "Line #{failure[:line]}: #{failure[:reference]} - #{failure[:error]}"
          end
          raise ActiveRecord::Rollback
        end

        def build_error(line, row, error)
          {
            line: line,
            reference: row["REFERENCE"],
            error: error.message,
            data: row.to_h
          }
        end
      end
    end
  end
end
