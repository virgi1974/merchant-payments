module Infrastructure
  module Presenters
    module Api
      module V1
        class MerchantPresenter
          def self.created(merchant)
            {
              json: { id: merchant.id },
              status: :created
            }
          end

          def self.error(message, status)
            {
              json: { error: message },
              status: status
            }
          end
        end
      end
    end
  end
end
