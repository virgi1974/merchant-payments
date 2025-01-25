require "rails_helper"

RSpec.describe Infrastructure::Persistence::ActiveRecord::Models::Merchant do
  let(:valid_attributes) do
    {
      id: SecureRandom.uuid,
      reference: "MERCH123",
      email: "merchant@example.com",
      live_on: Date.current,
      disbursement_frequency: "daily", # 0 for DAILY
      minimum_monthly_fee_cents: 1000
    }
  end

  describe "validations" do
    subject(:merchant) do
      described_class.new(valid_attributes)
    end

    it "is valid with valid attributes" do
      expect(merchant).to be_valid
    end

    it "requires a reference" do
      merchant.reference = nil
      expect(merchant).not_to be_valid
      expect(merchant.errors[:reference]).to include("can't be blank")
    end

    it "requires an email" do
      merchant.email = nil
      expect(merchant).not_to be_valid
      expect(merchant.errors[:email]).to include("can't be blank")
    end

    it "requires a live_on date" do
      merchant.live_on = nil
      expect(merchant).not_to be_valid
      expect(merchant.errors[:live_on]).to include("can't be blank")
    end

    it "requires a disbursement_frequency" do
      merchant.disbursement_frequency = nil
      expect(merchant).not_to be_valid
      expect(merchant.errors[:disbursement_frequency]).to include("can't be blank")
    end

    it "requires a minimum_monthly_fee" do
      merchant.minimum_monthly_fee_cents = nil
      expect(merchant).not_to be_valid
      expect(merchant.errors[:minimum_monthly_fee_cents]).to include("can't be blank")
    end

    it "validates uniqueness of id and reference" do
      merchant.save!
      duplicate = described_class.new(merchant.attributes)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:id]).to include("has already been taken")
      expect(duplicate.errors[:reference]).to include("has already been taken")
    end

    it "validates email format" do
      merchant.email = "invalid-email"
      expect(merchant).not_to be_valid
      expect(merchant.errors[:email]).to include("is invalid")
    end

    it "validates minimum_monthly_fee is not negative" do
      merchant.minimum_monthly_fee_cents = -100
      expect(merchant).not_to be_valid
      expect(merchant.errors[:minimum_monthly_fee_cents]).to include("must be greater than or equal to 0")
    end

    it "validates disbursement_frequency values" do
      Domain::Merchants::ValueObjects::DisbursementFrequency.values.each do |frequency|
        merchant.disbursement_frequency = frequency.downcase
        expect(merchant).to be_valid
      end

      expect {
        merchant.disbursement_frequency = "invalid"
      }.to raise_error(ArgumentError, "'invalid' is not a valid disbursement_frequency")
    end

    it "monetizes minimum_monthly_fee" do
      merchant.minimum_monthly_fee = Money.new(2000)
      expect(merchant.minimum_monthly_fee_cents).to eq(2000)
      expect(merchant.minimum_monthly_fee).to eq(Money.new(2000))
    end

    it "assigns UUID if id is nil" do
      merchant.id = nil
      expect { merchant.valid? }.to change { merchant.id }.from(nil)
      expect(merchant.id).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
    end

    it "keeps existing UUID" do
      existing_uuid = SecureRandom.uuid
      merchant.id = existing_uuid
      expect { merchant.valid? }.not_to change { merchant.id }
    end
  end

  describe "associations" do
    let(:merchant) { described_class.new }

    it "has many orders" do
      expect(merchant).to respond_to(:orders)
      expect(merchant.orders).to be_a(ActiveRecord::Associations::CollectionProxy)
    end

    it "has many disbursements" do
      expect(merchant).to respond_to(:disbursements)
      expect(merchant.disbursements).to be_a(ActiveRecord::Associations::CollectionProxy)
    end

    it "has many monthly_fee_adjustments" do
      expect(merchant).to respond_to(:monthly_fee_adjustments)
      expect(merchant.monthly_fee_adjustments).to be_a(ActiveRecord::Associations::CollectionProxy)
    end
  end

  describe "scopes" do
    describe ".with_frequency" do
      let!(:daily_merchant) do
        described_class.create!(valid_attributes.merge(
          id: SecureRandom.uuid,
          reference: "DAILY123",
          disbursement_frequency: "daily"
        ))
      end

      let!(:weekly_merchant) do
        described_class.create!(valid_attributes.merge(
          id: SecureRandom.uuid,
          reference: "WEEKLY123",
          disbursement_frequency: "weekly"
        ))
      end

      it "filters merchants by frequency" do
        expect(described_class.with_frequency("daily")).to contain_exactly(daily_merchant)
        expect(described_class.with_frequency("weekly")).to contain_exactly(weekly_merchant)
      end
    end

    describe ".matching_weekday" do
      let(:tuesday) { Date.new(2024, 1, 15) } # A Tuesday
      let(:wednesday) { Date.new(2024, 1, 16) } # A Wednesday

      let!(:tuesday_merchant) do
        described_class.create!(valid_attributes.merge(
          id: SecureRandom.uuid,
          reference: "TUESDAY123",
          live_on: tuesday
        ))
      end

      let!(:wednesday_merchant) do
        described_class.create!(valid_attributes.merge(
          id: SecureRandom.uuid,
          reference: "WEDNESDAY123",
          live_on: wednesday
        ))
      end

      it "filters merchants by matching weekday" do
        expect(described_class.matching_weekday(tuesday)).to contain_exactly(tuesday_merchant)
        expect(described_class.matching_weekday(wednesday)).to contain_exactly(wednesday_merchant)
      end
    end

    describe ".with_pending_orders" do
      let(:merchant) do
        described_class.create!(valid_attributes.merge(
          id: SecureRandom.uuid,
          reference: "PENDING123"
        ))
      end

      let(:start_time) { 1.day.ago.beginning_of_day }
      let(:end_time) { Time.current.end_of_day }

      let!(:pending_order) do
        merchant.orders.create!(
          amount_cents: 1000,
          pending_disbursement: true,
          created_at: Time.current
        )
      end

      let!(:processed_order) do
        merchant.orders.create!(
          amount_cents: 1000,
          pending_disbursement: false,
          created_at: Time.current
        )
      end

      let!(:old_pending_order) do
        merchant.orders.create!(
          amount_cents: 1000,
          pending_disbursement: true,
          created_at: 2.days.ago
        )
      end

      it "returns merchants with pending orders in the given time window" do
        result = described_class.with_pending_orders(start_time: start_time, end_time: end_time)

        expect(result).to include(merchant)
        expect(result.first.orders).to include(pending_order)
        expect(result.first.orders).not_to include(processed_order)
        expect(result.first.orders).not_to include(old_pending_order)
      end
    end
  end
end
