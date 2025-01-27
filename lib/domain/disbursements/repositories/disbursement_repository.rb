module Domain
  module Disbursements
    module Repositories
      class DisbursementRepository
        DISBURSEMENT_MODEL = Infrastructure::Persistence::ActiveRecord::Models::Disbursement
        DISBURSEMENT_ENTITY = Domain::Disbursements::Entities::Disbursement
        ORDER_MODEL = Infrastructure::Persistence::ActiveRecord::Models::Order

        def create(attributes)
          new_disbursement = DISBURSEMENT_MODEL.create!(attributes)
          update_orders_status(attributes[:orders].map(&:id)) unless attributes[:orders].blank?

          full_attributes = new_disbursement.attributes.symbolize_keys.merge(
            { orders: attributes[:orders] }
          )
          DISBURSEMENT_ENTITY.new(full_attributes)
        end

        def find(id)
          record = DISBURSEMENT_MODEL.find(id)
          DISBURSEMENT_ENTITY.new(record.attributes.symbolize_keys)
        end

        def date_range
          return nil unless ORDER_MODEL.pending_disbursement.exists?

          ORDER_MODEL
            .pending_disbursement
            .date_range
        end

        def for_year(year)
          records = DISBURSEMENT_MODEL.for_year(year)

          {
            size: records.size,
            sum_amount: records.any? ? records.sum_amount_for_year(year) : 0,
            sum_fees: records.any? ? records.sum_fees_for_year(year) : 0
          }
        end

        private

        def update_orders_status(order_ids)
          ORDER_MODEL.mark_as_disbursed(order_ids)
        end
      end
    end
  end
end
