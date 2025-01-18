require "dry-types"

module Domain
  module Shared
    module Types
      include Dry.Types()

      UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i

      UUID = Types::String.constrained(format: UUID_REGEX)
      DisbursementFrequency = Dry::Types["string"].enum("DAILY", "WEEKLY")
      PositiveDecimal = Dry::Types["decimal"].constrained(gteq: 0)
      Email = Dry::Types["string"].constrained(format: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
    end
  end
end
