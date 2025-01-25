module Domain
  module Disbursements
    module Services
      module Calculators
        class Daily < Base
          protected

          def fetch_orders
            @orders_query.call(@merchant)
          end
        end
      end
    end
  end
end
