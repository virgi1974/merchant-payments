module Infrastructure
  module Persistence
    module ActiveRecord
      module Concerns
        module HasUuid
          extend ActiveSupport::Concern

          included do
            before_validation :assign_uuid, on: :create
          end

          private

          def assign_uuid
            self.id = SecureRandom.uuid if id.blank? || id.nil?
          end
        end
      end
    end
  end
end
