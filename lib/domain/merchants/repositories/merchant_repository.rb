module Domain
  module Merchants
    module Repositories
      class MerchantRepository
        MERCHANT_MODEL = Infrastructure::Persistence::ActiveRecord::Models::Merchant
        MERCHANT_ENTITY = Domain::Merchants::Entities::Merchant

        def create(attributes)
          new_merchant = MERCHANT_MODEL.create!(attributes)
          MERCHANT_ENTITY.new(new_merchant.attributes.symbolize_keys)
        end

        def find(id)
          record = MERCHANT_MODEL.find(id)
          MERCHANT_ENTITY.new(record.attributes.symbolize_keys)
        end
      end
    end
  end
end
