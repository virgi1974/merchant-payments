module Domain
  module Merchants
    module Repositories
      class MerchantRepository
        MERCHANT_MODEL = Infrastructure::Persistence::ActiveRecord::Models::Merchant
        MERCHANT_ENTITY = Domain::Merchants::Entities::Merchant
        ORDER_ENTITY = Domain::Orders::Entities::Order
        DISBURSABLE_MERCHANT_ENTITY = Domain::Merchants::Entities::DisbursableMerchant
        BATCH_SIZE = 100

        def create(attributes)
          new_merchant = MERCHANT_MODEL.create!(attributes)
          MERCHANT_ENTITY.new(new_merchant.attributes.symbolize_keys)
        end

        def find(id)
          record = MERCHANT_MODEL.find(id)
          MERCHANT_ENTITY.new(record.attributes.symbolize_keys)
        end

        def find_disbursable_merchants(date)
          find_disbursable_daily.or(find_disbursable_weekly(date)).map do |record|
            DISBURSABLE_MERCHANT_ENTITY.new(record.attributes.symbolize_keys)
          end
        end

        def find_disbursable_merchants_in_batches(date)
          find_disbursable_daily
            .or(find_disbursable_weekly(date))
            .find_each(batch_size: BATCH_SIZE)
            .map { |record| DISBURSABLE_MERCHANT_ENTITY.new(record.attributes.symbolize_keys) }
        end

        private

        def find_disbursable_daily
          MERCHANT_MODEL.with_frequency("daily")
        end

        def find_disbursable_weekly(date)
          MERCHANT_MODEL
            .with_frequency("weekly")
            .matching_weekday(date)
        end
      end
    end
  end
end
