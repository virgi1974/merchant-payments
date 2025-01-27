module Domain
  module Disbursements
    module Factories
      class FrequencyBasedFactory
        SERVICES = {
          "daily" => Domain::Disbursements::Services::Calculators::Daily,
          "weekly" => Domain::Disbursements::Services::Calculators::Weekly
        }.freeze

        def self.create(frequency, merchant, date, repository, skip_live_on_check)
          service_class = SERVICES[frequency] or
            raise Errors::InvalidFrequencyError, "Unknown frequency: #{frequency}"

          service_class.new(merchant, date, repository, skip_live_on_check)
        end
      end
    end
  end
end
