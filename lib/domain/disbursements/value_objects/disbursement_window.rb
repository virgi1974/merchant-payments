module Domain
  module Disbursements
    module ValueObjects
      class DisbursementWindow
        def initialize(date, frequency)
          @date = date
          @frequency = frequency
        end

        def end_time
          # Previous day end (23:59:59 UTC)
          (@date - 1.day).end_of_day.utc
        end

        def start_time
          case @frequency
          when "daily"
            # Previous day start (00:00:00 UTC)
            (@date - 1.day).beginning_of_day.utc
          when "weekly"
            # 7 full days back, ending yesterday
            (@date - 7.days).beginning_of_day.utc
          else
            raise ArgumentError, "Unknown frequency: #{@frequency}"
          end
        end
      end
    end
  end
end
