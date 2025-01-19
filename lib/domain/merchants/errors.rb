module Domain
  module Merchants
    module Errors
      class ValidationError < StandardError; end
      class InvalidDisbursementFrequency < ValidationError; end
      class InvalidMinimumMonthlyFee < ValidationError; end
      class InvalidCsvFormat < ValidationError; end
    end
  end
end
