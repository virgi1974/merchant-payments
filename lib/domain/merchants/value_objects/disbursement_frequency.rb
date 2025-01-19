module Domain
  module Merchants
    module ValueObjects
      class DisbursementFrequency
        FREQUENCIES = {
          daily: 0,
          weekly: 1
        }.freeze

        VALID_VALUES = FREQUENCIES.keys.map(&:to_s).map(&:upcase).freeze

        def self.valid?(value)
          VALID_VALUES.include?(value)
        end

        def self.normalize(value)
          value.downcase.to_sym
        end

        def self.values
          VALID_VALUES
        end
      end
    end
  end
end
