module Domain
  module Fees
    module Repositories
      class MerchantRepository
        MERCHANT_MODEL = Infrastructure::Persistence::ActiveRecord::Models::Merchant
        BATCH_SIZE = 1000

        def find_all_merchants_in_batches
          MERCHANT_MODEL.find_each(batch_size: BATCH_SIZE)
        end
      end
    end
  end
end
