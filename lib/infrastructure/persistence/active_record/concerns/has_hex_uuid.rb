module Infrastructure
  module Persistence
    module ActiveRecord
      module Concerns
        module HasHexUuid
          extend ActiveSupport::Concern

          included do
            before_validation :assign_hex_uuid, on: :create
          end

          private

          def assign_hex_uuid
            self.id = SecureRandom.hex(6) if id.blank? || id.nil?
          end
        end
      end
    end
  end
end
