module Domain
  module Orders
    module Services
      module Importers
        class CsvImporter
          CSV_VALIDATOR = Domain::Orders::Services::CsvValidator
          CSV_RECORD_VALIDATOR = Domain::Orders::Data::CsvRecordValidator
          CSV_ORDER_CREATOR = Domain::Orders::Services::OrderCreators::CsvCreator

          def self.call(csv_path)
            new(csv_path).call
          end

          def initialize(csv_path)
            @csv_path = csv_path
            @failed_orders = []
            @imported_count = 0
          end

          def call
            logger.info "Starting orders import at #{Time.current}"
            validation = CSV_VALIDATOR.call(csv_path)

            unless validation[:valid]
              validation[:errors].each { |error| logger.error(error) }
              return { success: false, error: validation[:errors].join(", ") }
            end

            initialize_csv_record_validator(validation[:separator])

            batch_size = 1000
            orders_batch = []

            CSV.foreach(csv_path, headers: true, col_sep: validation[:separator]) do |row|
              orders_batch << row

              if orders_batch.size >= batch_size
                process_batch(orders_batch)
                orders_batch = []
              end
            end

            # Process remaining records
            process_batch(orders_batch) if orders_batch.any?

            logger.info "Successfully imported #{@imported_count} orders"

            {
              success: true,
              imported_count: @imported_count,
              failed_count: @failed_orders.count,
              failures: @failed_orders
            }
          rescue CSV::MalformedCSVError => e
            logger.error "CSV parsing error: #{e.message}"
            { success: false, error: e.message }
          rescue Errno::ENOENT => e
            logger.error "CSV file not found: #{e.message}"
            { success: false, error: e.message }
          end

          private

          attr_reader :csv_path, :failed_orders
          attr_accessor :imported_count

          def initialize_csv_record_validator(separator)
            @csv_record_validator = CSV_RECORD_VALIDATOR.call(separator)
          end

          def import_order(row, line)
            order_data = @csv_record_validator.process_row(row)
            CSV_ORDER_CREATOR.call(order_data)
            @imported_count += 1
          rescue Dry::Struct::Error => e
            failed_orders << build_error(line, row, e)
            logger.error "Invalid data at line #{line}: #{e.message}"
          rescue StandardError => e
            failed_orders << build_error(line, row, e)
            logger.error "Failed to import order at line #{line}: #{e.message}"
          end

          def handle_failures
            return unless failed_orders.any?

            logger.error "Import failed for #{failed_orders.count} orders:"
            failed_orders.each do |failure|
              logger.error "Line #{failure[:line]}: #{failure[:id]} - #{failure[:error]}"
            end
          end

          def build_error(line, row, error)
            {
              line: line,
              id: row["id"],
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

          def process_batch(batch)
            ActiveRecord::Base.transaction do
              batch.each_with_index do |row, index|
                import_order(row, $. - batch.size + index + 1)
              end
            end
          end
        end
      end
    end
  end
end
