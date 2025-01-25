module Domain
  module Disbursements
    module Factories
      class FrequencyBasedFactory
        SERVICES = {
          "daily" => Domain::Disbursements::Services::Calculators::Daily,
          "weekly" => Domain::Disbursements::Services::Calculators::Weekly
        }.freeze

        def self.create(frequency, merchant, date, repository)
          service_class = SERVICES[frequency] or
            raise Errors::InvalidFrequencyError, "Unknown frequency: #{frequency}"

          service_class.new(merchant, date, repository)
        end
      end
    end
  end
end
