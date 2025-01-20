require "rails_helper"

RSpec.describe Domain::Merchants::ValueObjects::DisbursementFrequency do
  describe ".valid?" do
    it "returns true for valid frequencies" do
      expect(described_class.valid?("DAILY")).to be true
      expect(described_class.valid?("WEEKLY")).to be true
    end

    it "returns false for invalid frequencies" do
      expect(described_class.valid?("MONTHLY")).to be false
      expect(described_class.valid?("INVALID")).to be false
      expect(described_class.valid?("")).to be false
    end
  end

  describe ".normalize" do
    it "converts frequency to downcased symbol" do
      expect(described_class.normalize("DAILY")).to eq(:daily)
      expect(described_class.normalize("WEEKLY")).to eq(:weekly)
    end
  end

  describe ".values" do
    it "returns array of valid frequencies" do
      expect(described_class.values).to match_array([ "DAILY", "WEEKLY" ])
    end
  end
end
