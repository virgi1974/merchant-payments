require "rails_helper"

RSpec.describe Infrastructure::Persistence::ActiveRecord::Concerns::HasDisbursementUuid do
  let(:merchant) do
    Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
      id: SecureRandom.uuid,
      reference: "MERCH123",
      email: "merchant@example.com",
      live_on: Date.current,
      disbursement_frequency: 0,
      minimum_monthly_fee_cents: 1000
    )
  end

  let(:test_class) do
    Class.new(ApplicationRecord) do
      self.table_name = "disbursements"

      # Include the concern we're testing
      include Infrastructure::Persistence::ActiveRecord::Concerns::HasDisbursementUuid

      # Add required association
      belongs_to :merchant, class_name: "Infrastructure::Persistence::ActiveRecord::Models::Merchant"
    end
  end

  before do
    # Ensure the class is properly named within the module hierarchy
    stub_const("Infrastructure::Persistence::ActiveRecord::Models::TestDisbursement", test_class)
  end

  describe "#generate_disbursement_uuid" do
    let(:valid_attributes) do
      {
        merchant: merchant,
        amount_cents: 10000,
        fees_amount_cents: 100,
        disbursed_at: nil
      }
    end

    it "generates a disbursement UUID before create" do
      instance = test_class.new(valid_attributes)
      instance.save!
      expect(instance.id).to match(/^DISB-#{merchant.id}-\d+$/)
    end

    it "generates unique IDs for multiple records" do
      instance1 = test_class.new(valid_attributes)
      instance2 = test_class.new(valid_attributes)

      instance1.save!
      sleep(1)  # Ensure different timestamps
      instance2.save!

      expect(instance1.id).not_to eq(instance2.id)
    end

    it "includes merchant id in the generated UUID" do
      instance = test_class.new(valid_attributes)
      instance.save!
      expect(instance.id).to include(merchant.id)
    end

    it "follows the DISB-merchantid-timestamp format" do
      instance = test_class.new(valid_attributes)
      instance.save!

      id_parts = instance.id.split("-")
      expect(id_parts[0]).to eq("DISB")
      # Reconstruct merchant UUID from parts
      merchant_uuid = id_parts[1..5].join("-")
      expect(merchant_uuid).to eq(merchant.id)
      expect(id_parts.last).to match(/^\d+$/)  # timestamp is the last part
    end
  end
end
