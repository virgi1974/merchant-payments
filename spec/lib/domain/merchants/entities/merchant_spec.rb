require "rails_helper"

RSpec.describe Domain::Merchants::Entities::Merchant do
  let(:current_date) { Date.new(2024, 3, 20) }  # Wednesday
  let(:valid_attributes) do
    {
      id: SecureRandom.uuid,
      reference: "MERCH123",
      email: "merchant@example.com",
      live_on: current_date,
      disbursement_frequency: :daily,  # Changed to symbol
      minimum_monthly_fee_cents: 1000 # 10.00 EUR in cents
    }
  end

  describe ".new" do
    subject(:merchant) { described_class.new(valid_attributes) }

    it "creates a merchant with valid attributes" do
      expect(merchant).to be_a(described_class)
    end

    it "sets the id" do
      expect(merchant.id).to eq(valid_attributes[:id])
    end

    it "sets the reference" do
      expect(merchant.reference).to eq("MERCH123")
    end

    it "sets the email" do
      expect(merchant.email).to eq("merchant@example.com")
    end

    it "sets the live_on date" do
      expect(merchant.live_on).to eq(current_date)
    end

    it "sets the disbursement_frequency" do
      expect(merchant.disbursement_frequency).to eq(:daily)
    end

    it "creates Money object from cents" do
      expect(merchant.minimum_monthly_fee).to be_a(Money)
      expect(merchant.minimum_monthly_fee.cents).to eq(1000)
    end
  end

  describe "#ready_for_disbursement?" do
    context "when disbursement is daily" do
      let(:merchant) { described_class.new(valid_attributes) }

      it "returns true for any date" do
        expect(merchant.ready_for_disbursement?(current_date)).to be true
      end
    end

    context "when disbursement is weekly" do
      let(:merchant) { described_class.new(valid_attributes.merge(disbursement_frequency: :weekly)) }

      it "returns true when date matches live_on day" do
        expect(merchant.ready_for_disbursement?(current_date)).to be true
      end

      it "returns false when date doesn't match live_on day" do
        next_day = current_date + 1  # Thursday
        expect(merchant.ready_for_disbursement?(next_day)).to be false
      end
    end
  end

  describe "#calculate_monthly_fee" do
    let(:merchant) { described_class.new(valid_attributes) }

    context "when month fees exceed minimum" do
      it "returns zero" do
        month_fees = Money.new(2000) # 20.00 EUR
        expect(merchant.calculate_monthly_fee(month_fees)).to eq(Money.new(0))
      end
    end

    context "when month fees are below minimum" do
      it "returns the difference" do
        month_fees = Money.new(500) # 5.00 EUR
        expect(merchant.calculate_monthly_fee(month_fees)).to eq(Money.new(500)) # 10.00 - 5.00 = 5.00 EUR
      end
    end
  end
end
