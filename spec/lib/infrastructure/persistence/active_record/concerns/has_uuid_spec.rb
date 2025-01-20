require "rails_helper"

RSpec.describe Infrastructure::Persistence::ActiveRecord::Concerns::HasUuid do
  let(:test_class) do
    Class.new(ApplicationRecord) do
      include Infrastructure::Persistence::ActiveRecord::Concerns::HasUuid
      self.table_name = "merchants" # Use existing table for testing
    end
  end

  describe "#assign_uuid" do
    it "assigns UUID before validation on create" do
      record = test_class.new
      expect { record.valid? }.to change { record.id }.from(nil)
      expect(record.id).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
    end

    it "doesn't change existing UUID" do
      existing_uuid = SecureRandom.uuid
      record = test_class.new(id: existing_uuid)
      expect { record.valid? }.not_to change { record.id }
    end
  end
end
