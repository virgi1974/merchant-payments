module Infrastructure
  module Persistence
    module ActiveRecord
      module Concerns
        module HasDisbursementUuid
          extend ActiveSupport::Concern

          included do
            before_create :generate_disbursement_uuid
          end

          private

          def generate_disbursement_uuid
            self.id = "DISB-#{merchant.id}-#{Time.current.to_i}"
          end
        end
      end
    end
  end
end
