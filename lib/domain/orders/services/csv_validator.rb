module Domain
  module Orders
    module Services
      class CsvValidator
        REQUIRED_HEADERS = [ "id", "merchant_reference", "amount", "created_at" ].freeze
        VALID_SEPARATORS = [ ",", ";", "\t" ].freeze

        def self.call(csv_path)
          new(csv_path).call
        end

        def initialize(csv_path)
          @csv_path = csv_path
          @errors = []
        end

        def call
          return { valid: false, errors: [ "CSV file not found: #{csv_path}" ], separator: nil } unless File.exist?(csv_path)
          return { valid: false, errors: [ "CSV file is empty" ], separator: nil } if File.zero?(csv_path)

          separator = detect_separator
          validate_separator(separator)
          return { valid: false, errors: errors, separator: separator } if errors.any?

          headers = CSV.read(csv_path, headers: true, col_sep: separator).headers
          validate_headers(headers)
          return { valid: false, errors: errors, separator: separator } if errors.any?

          {
            valid: true,
            errors: [],
            separator: separator
          }
        rescue CSV::MalformedCSVError => e
          { valid: false, errors: [ "Invalid CSV format: #{e.message}" ], separator: nil }
        end

        private

        attr_reader :csv_path, :errors

        def validate_headers(headers)
          normalized_headers = headers.map(&:downcase)
          missing = REQUIRED_HEADERS.map(&:downcase) - normalized_headers
          errors << "Missing required headers: #{missing.join(", ")}" if missing.any?
        end

        def detect_separator
          first_line = File.open(csv_path, &:readline)

          VALID_SEPARATORS.each do |separator|
            fields = parse_line_with_separator(first_line, separator)
            return separator if fields&.size.to_i > 1
          end

          raise CSV::MalformedCSVError.new("Could not detect valid separator", 1)
        end

        def parse_line_with_separator(line, separator)
          CSV.parse_line(line, col_sep: separator)
        rescue CSV::MalformedCSVError
          nil
        end

        def validate_separator(separator)
          return if VALID_SEPARATORS.include?(separator)
          errors << "Invalid separator detected. Valid separators are: #{VALID_SEPARATORS.join(", ")}"
        end
      end
    end
  end
end
