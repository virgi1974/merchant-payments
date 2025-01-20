module Domain
  module Orders
    module Repositories
      class OrderRepository
        ORDER_MODEL = Infrastructure::Persistence::ActiveRecord::Models::Order
        ORDER_ENTITY = Domain::Orders::Entities::Order

        def create(attributes)
          new_order = ORDER_MODEL.create!(attributes)
          ORDER_ENTITY.new(new_order.attributes.symbolize_keys)
        end

        def find(id)
          record = ORDER_MODEL.find(id)
          ORDER_ENTITY.new(record.attributes.symbolize_keys)
        end
      end
    end
  end
end
