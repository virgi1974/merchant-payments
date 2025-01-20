module Domain
  module Orders
    module Errors
      class ValidationError < StandardError; end
      class InvalidCsvFormat < ValidationError; end
      class InvalidMinimumAmount < ValidationError; end
    end
  end
end
