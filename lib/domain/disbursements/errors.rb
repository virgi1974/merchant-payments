module Domain
  module Disbursements
    module Errors
      class ValidationError < StandardError; end
      class InvalidAmount < ValidationError; end
      class InvalidFees < ValidationError; end
      class NoOrdersToProcess < ValidationError; end
      class DisbursementProcessingError < StandardError; end
      class InvalidFrequencyError < StandardError; end
    end
  end
end
