module Domain
  module Orders
    module Repositories
      class OrderRepository
        ORDER_MODEL = Infrastructure::Persistence::ActiveRecord::Models::Order
        ORDER_ENTITY = Domain::Orders::Entities::Order
        MERCHANT_MODEL = Infrastructure::Persistence::ActiveRecord::Models::Merchant

        def create(attributes)
          new_order = ORDER_MODEL.create!(attributes)
          ORDER_ENTITY.new(new_order.attributes.symbolize_keys)
        end

        def find(id)
          record = ORDER_MODEL.find(id)
          ORDER_ENTITY.new(record.attributes.symbolize_keys)
        end

        def find_pending_for_merchant(merchant_reference, start_time:, end_time:)
          ORDER_MODEL
            .where(merchant_reference: merchant_reference)
            .pending_disbursement
            .where("created_at BETWEEN ? AND ?", start_time, end_time)
            .by_creation
        end
      end
    end
  end
end
