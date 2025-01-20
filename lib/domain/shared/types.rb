require "dry-types"

module Domain
  module Shared
    module Types
      include Dry.Types()

      UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i

      UUID = Types::String.constrained(format: UUID_REGEX)
      DisbursementFrequency = Types::String.enum(*Domain::Merchants::ValueObjects::DisbursementFrequency.values)
      PositiveDecimal = Types::Decimal.constructor { |v| BigDecimal(v.to_s) }
                                    .constrained(gteq: 0)
      Email = Types::String.constrained(format: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
      Date = Types::Date.constructor(proc { |value| ::Date.parse(value.to_s) })

      HEX_ID_REGEX = /\A[0-9a-f]{12}\z/i
      HexId = Types::String.constrained(format: HEX_ID_REGEX)
    end
  end
end
