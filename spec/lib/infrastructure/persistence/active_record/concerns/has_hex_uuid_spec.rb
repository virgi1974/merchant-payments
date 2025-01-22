require "rails_helper"

RSpec.describe Infrastructure::Persistence::ActiveRecord::Concerns::HasHexUuid do
  let(:test_class) do
    Class.new(ApplicationRecord) do
      include Infrastructure::Persistence::ActiveRecord::Concerns::HasHexUuid
      self.table_name = "orders" # Use existing table for testing
    end
  end

  describe "#assign_hex_uuid" do
    it "assigns hex ID before validation on create" do
      record = test_class.new
      expect { record.valid? }.to change { record.id }.from(nil)
      expect(record.id).to match(/\A[0-9a-f]{12}\z/i)
    end

    it "doesn't change existing hex ID" do
      existing_id = SecureRandom.hex(6)
      record = test_class.new(id: existing_id)
      expect { record.valid? }.not_to change { record.id }
    end
  end
end
