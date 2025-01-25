module Domain
  module Disbursements
    module Repositories
      class DisbursementRepository
        DISBURSEMENT_MODEL = Infrastructure::Persistence::ActiveRecord::Models::Disbursement
        DISBURSEMENT_ENTITY = Domain::Disbursements::Entities::Disbursement

        def create(attributes)
          new_disbursement = DISBURSEMENT_MODEL.create!(attributes)
          full_attributes = new_disbursement.attributes.symbolize_keys.merge(
            { orders: attributes[:orders] }
          )
          DISBURSEMENT_ENTITY.new(full_attributes)
        end

        def find(id)
          record = DISBURSEMENT_MODEL.find(id)
          DISBURSEMENT_ENTITY.new(record.attributes.symbolize_keys)
        end
      end
    end
  end
end
