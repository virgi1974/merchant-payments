# app/domain/merchants/services/import_merchants.rb
module Domain
  module Merchants
    module Services
      module Importers
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
            logger.info "Starting merchants import at #{Time.current}"
            validation = CSV_VALIDATOR.call(csv_path)

            unless validation[:valid]
              validation[:errors].each { |error| logger.error(error) }
              return { success: false, errors: validation[:errors] }
            end

            initialize_csv_record_validator(validation[:separator])
            csv = CSV.read(csv_path, headers: true, col_sep: validation[:separator])

            ActiveRecord::Base.transaction do
              csv.each.with_index(2) do |row, line|
                import_merchant(row, line)
              end

              handle_failures
            end

            logger.info "Successfully imported #{@imported_count} merchants"

            {
              success: true,
              imported_count: @imported_count,
              failed_count: @failed_merchants.count,
              failures: @failed_merchants
            }
          rescue CSV::MalformedCSVError => e
            logger.error "CSV parsing error: #{e.message}"
            { success: false, error: e.message }
          rescue Errno::ENOENT => e
            logger.error "CSV file not found: #{e.message}"
            { success: false, error: e.message }
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
            logger.error "Invalid data at line #{line}: #{e.message}"
          rescue StandardError => e

            failed_merchants << build_error(line, row, e)
            logger.error "Failed to import merchant at line #{line}: #{e.message}"
          end

          def handle_failures
            return unless failed_merchants.any?

            logger.error "Import failed for #{failed_merchants.count} merchants:"
            failed_merchants.each do |failure|
              logger.error "Line #{failure[:line]}: #{failure[:reference]} - #{failure[:error]}"
            end
          end

          def build_error(line, row, error)
            {
              line: line,
              reference: row["REFERENCE"],
              error: error.message,
              data: row.to_h
            }
          end

          def logger
            @logger ||= begin
              logger = Logger.new($stdout)
              logger.formatter = proc do |severity, datetime, progname, msg|
                "#{datetime}: #{msg}\n"
              end
              logger
            end
          end
        end
      end
    end
  end
end
