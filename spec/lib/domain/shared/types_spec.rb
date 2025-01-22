require "rails_helper"

RSpec.describe Domain::Shared::Types do
  describe "UUID" do
    let(:valid_uuid) { "123e4567-e89b-4d3c-a456-426614174000" }
    let(:invalid_uuid) { "not-a-uuid" }

    it "accepts valid UUID" do
      expect { described_class::UUID[valid_uuid] }.not_to raise_error
    end

    it "rejects invalid UUID" do
      expect { described_class::UUID[invalid_uuid] }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe "DisbursementFrequency" do
    it "accepts valid frequencies" do
      expect { described_class::DisbursementFrequency["DAILY"] }.not_to raise_error
      expect { described_class::DisbursementFrequency["WEEKLY"] }.not_to raise_error
    end

    it "rejects lowercase frequencies" do
      expect { described_class::DisbursementFrequency["daily"] }.to raise_error(Dry::Types::ConstraintError)
      expect { described_class::DisbursementFrequency["weekly"] }.to raise_error(Dry::Types::ConstraintError)
    end

    it "rejects invalid frequencies" do
      expect { described_class::DisbursementFrequency["MONTHLY"] }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe "PositiveDecimal" do
    it "accepts positive numbers" do
      expect(described_class::PositiveDecimal[10]).to eq(BigDecimal("10"))
      expect(described_class::PositiveDecimal["10.5"]).to eq(BigDecimal("10.5"))
    end

    it "rejects negative numbers" do
      expect { described_class::PositiveDecimal[-1] }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe "Email" do
    it "accepts valid emails" do
      expect { described_class::Email["user@example.com"] }.not_to raise_error
    end

    it "rejects invalid emails" do
      expect { described_class::Email["not-an-email"] }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe "Date" do
    it "accepts valid dates" do
      expect(described_class::Date["2024-03-20"]).to eq(Date.new(2024, 3, 20))
      expect(described_class::Date[Date.today]).to eq(Date.today)
    end

    it "rejects invalid dates" do
      expect { described_class::Date["not-a-date"] }.to raise_error(Dry::Types::CoercionError)
    end
  end

  describe "HexId" do
    it "accepts valid hex IDs" do
      expect { described_class::HexId["123abc456def"] }.not_to raise_error
      expect { described_class::HexId["ABCDEF123456"] }.not_to raise_error
    end

    it "rejects invalid hex IDs" do
      expect { described_class::HexId["123abc"] }.to raise_error(Dry::Types::ConstraintError) # too short
      expect { described_class::HexId["123abc456defgh"] }.to raise_error(Dry::Types::ConstraintError) # too long
      expect { described_class::HexId["123abc456xyz"] }.to raise_error(Dry::Types::ConstraintError) # invalid chars
      expect { described_class::HexId["not-a-hex-id"] }.to raise_error(Dry::Types::ConstraintError)
    end
  end
end
