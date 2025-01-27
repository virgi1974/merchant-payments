module Domain
  module Disbursements
    module Services
      module Calculators
        class Weekly < Base
          protected

          def fetch_orders
            return [] unless process_today?

            @orders_query.call(@merchant)
          end

          private

          def process_today?
            @skip_live_on_check ? true : @merchant.live_on.wday == @date.wday
          end
        end
      end
    end
  end
end
