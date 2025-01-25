module Domain
  module Disbursements
    module Queries
      class PendingOrdersQuery
        def initialize(date = Date.current)
          @date = date
          @repository = Orders::Repositories::OrderRepository.new
        end

        def call(merchant)
          window = ValueObjects::DisbursementWindow.new(@date, merchant.disbursement_frequency)

          @repository.find_pending_for_merchant(
            merchant.reference,
            start_time: window.start_time,
            end_time: window.end_time
          )
        end
      end
    end
  end
end
