require "rails_helper"

RSpec.describe Domain::Disbursements::Services::FeeCalculator do
  subject(:calculator) { described_class.new }

  describe "#calculate_total_fees" do
    let(:order1) { instance_double("Order", amount_cents: amount1) }
    let(:order2) { instance_double("Order", amount_cents: amount2) }
    let(:orders) { [ order1, order2 ] }

    context "when all orders are in the same fee tier" do
      context "with amounts < 50€ (1.0% fee)" do
        let(:amount1) { 2000 } # 20€
        let(:amount2) { 3000 } # 30€

        it "calculates total fees correctly" do
          # 20€ * 0.01 = 20 cents
          # 30€ * 0.01 = 30 cents
          expect(calculator.calculate_total_fees(orders)).to eq(50)
        end
      end

      context "with amounts between 50€ and 300€ (0.95% fee)" do
        let(:amount1) { 10000 } # 100€
        let(:amount2) { 20000 } # 200€

        it "calculates total fees correctly" do
          # 100€ * 0.0095 = 95 cents
          # 200€ * 0.0095 = 190 cents
          expect(calculator.calculate_total_fees(orders)).to eq(285)
        end
      end

      context "with amounts >= 300€ (0.85% fee)" do
        let(:amount1) { 35000 } # 350€
        let(:amount2) { 45000 } # 450€

        it "calculates total fees correctly" do
          # 350€ * 0.0085 = 298 cents (297.5 rounded)
          # 450€ * 0.0085 = 383 cents (382.5 rounded)
          expect(calculator.calculate_total_fees(orders)).to eq(681)
        end
      end
    end

    context "when orders span different fee tiers" do
      let(:amount1) { 4000 }  # 40€ (1.0% fee)
      let(:amount2) { 6000 }  # 60€ (0.95% fee)
      let(:amount3) { 35000 } # 350€ (0.85% fee)
      let(:orders) { [ order1, order2, order3 ] }
      let(:order3) { instance_double("Order", amount_cents: amount3) }

      it "calculates total fees correctly for each tier" do
        # 40€ * 0.01 = 40 cents
        # 60€ * 0.0095 = 57 cents
        # 350€ * 0.0085 = 298 cents (297.5 rounded)
        expect(calculator.calculate_total_fees(orders)).to eq(395)
      end
    end

    context "when orders list is empty" do
      it "returns 0" do
        expect(calculator.calculate_total_fees([])).to eq(0)
      end
    end

    context "at fee tier boundaries" do
      context "at 50€ boundary" do
        let(:amount1) { 4999 } # 49.99€ (1.0% fee)
        let(:amount2) { 5000 } # 50€ (0.95% fee)

        it "applies correct fee rates" do
          # 49.99€ * 0.01 = 50 cents (49.99 rounded)
          # 50€ * 0.0095 = 48 cents (47.5 rounded)
          expect(calculator.calculate_total_fees(orders)).to eq(98)
        end
      end

      context "at 300€ boundary" do
        let(:amount1) { 29999 } # 299.99€ (0.95% fee)
        let(:amount2) { 30000 } # 300€ (0.85% fee)

        it "applies correct fee rates" do
          # 299.99€ * 0.0095 = 284.99 cents rounded to 285 cents
          # 300€ * 0.0085 = 255 cents
          expect(calculator.calculate_total_fees(orders)).to eq(570)
        end
      end
    end

    context "with edge cases" do
      context "with very large amount" do
        let(:amount1) { 10_000_000 } # 100,000€
        let(:orders) { [ order1 ] }

        it "calculates correctly" do
          # 100,000€ * 0.0085 = 850€ = 85,000 cents
          expect(calculator.calculate_total_fees(orders)).to eq(85_000)
        end
      end

      context "with minimum valid amount" do
        let(:amount1) { 1 } # 0.01€
        let(:orders) { [ order1 ] }

        it "calculates fee correctly" do
          # 0.01€ * 0.01 = 0.0001€ rounded to 0 cents
          expect(calculator.calculate_total_fees(orders)).to eq(0)
        end
      end
    end
  end
end
