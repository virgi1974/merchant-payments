module HasUuid
  extend ActiveSupport::Concern

  included do
    before_create :assign_uuid
  end

  private

  def assign_uuid
    self.id = SecureRandom.uuid if id.blank?
  end
end
