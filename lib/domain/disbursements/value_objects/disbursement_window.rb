module Domain
  module Disbursements
    module ValueObjects
      class DisbursementWindow
        def initialize(date, frequency)
          @date = date
          @frequency = frequency
        end

        def end_time
          @date.end_of_day.utc
        end

        def start_time
          case @frequency
          when "daily"
            @date.beginning_of_day.utc
          when "weekly"
            (@date - 6.days).beginning_of_day.utc
          else
            raise ArgumentError, "Unknown frequency: #{@frequency}"
          end
        end
      end
    end
  end
end
