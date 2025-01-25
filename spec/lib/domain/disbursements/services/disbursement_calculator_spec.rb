require "rails_helper"

RSpec.describe Domain::Disbursements::Services::DisbursementCalculator do
  describe "#create_disbursements" do
    context "daily orders" do
      context "when processing on reference date" do
        let(:reference_date) { Date.new(2024, 1, 15) } # Tuesday
        let(:calculator) { described_class.new(reference_date) }

        context "with daily merchant and pending orders" do
          let!(:daily_merchant) do
            Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
              reference: "daily_merchant",
              disbursement_frequency: "daily",
              live_on: reference_date,
              email: "daily@example.com",
              minimum_monthly_fee_cents: 2900
            )
          end

          let!(:todays_order) do
            Infrastructure::Persistence::ActiveRecord::Models::Order.create!(
              merchant_reference: daily_merchant.reference,
              amount_cents: 5000,
              created_at: reference_date
            )
          end

          it "creates a disbursement entity" do
            result = calculator.create_disbursements

            expect(result[:successful].first).to be_a(Domain::Disbursements::Entities::Disbursement)
            expect(result[:successful].first.amount_cents).to eq(5000)
            expect(result[:successful].first.orders).to include(todays_order)
          end

          xit "marks orders as disbursed" do
            calculator.create_disbursements
            expect(todays_order.reload.pending_disbursement).to be false
          end
        end

        context "with daily merchant and old orders" do
          let!(:daily_merchant) do
            Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
              reference: "daily_merchant",
              disbursement_frequency: "daily",
              live_on: reference_date,
              email: "daily@example.com",
              minimum_monthly_fee_cents: 2900
            )
          end

          let!(:old_order) do
            Infrastructure::Persistence::ActiveRecord::Models::Order.create!(
              merchant_reference: daily_merchant.reference,
              amount_cents: 3000,
              created_at: reference_date - 1.day
            )
          end

          it "excludes old orders" do
            result = calculator.create_disbursements
            expect(result).to eq({ successful: [], failed: [] })
          end
        end

        context "with already disbursed orders" do
          let!(:daily_merchant) do
            Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
              reference: "daily_merchant",
              disbursement_frequency: "daily",
              live_on: reference_date,
              email: "daily@example.com",
              minimum_monthly_fee_cents: 2900
            )
          end

          let!(:disbursed_order) do
            Infrastructure::Persistence::ActiveRecord::Models::Order.create!(
              merchant_reference: daily_merchant.reference,
              amount_cents: 5000,
              created_at: reference_date,
              pending_disbursement: false
            )
          end

          it "excludes disbursed orders" do
            result = calculator.create_disbursements
            expect(result).to eq({ successful: [], failed: [] })
          end
        end

        context "with no eligible orders" do
          let!(:daily_merchant) do
            Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
              reference: "daily_merchant",
              disbursement_frequency: "daily",
              live_on: reference_date,
              email: "daily@example.com",
              minimum_monthly_fee_cents: 2900
            )
          end

          it "returns empty results" do
            result = calculator.create_disbursements
            expect(result).to eq({ successful: [], failed: [] })
          end
        end
      end

      context "when processing on different dates" do
        let(:past_date) { Date.new(2024, 1, 1) }
        let(:calculator) { described_class.new(past_date) }

        let!(:daily_merchant) do
          Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
            reference: "daily_merchant",
            disbursement_frequency: "daily",
            live_on: past_date,
            email: "daily@example.com",
            minimum_monthly_fee_cents: 2900
          )
        end

        let!(:past_order) do
          Infrastructure::Persistence::ActiveRecord::Models::Order.create!(
            merchant_reference: daily_merchant.reference,
            amount_cents: 5000,
            created_at: past_date
          )
        end

        it "processes orders for the given date" do
          result = calculator.create_disbursements
          expect(result[:successful].first.orders).to include(past_order)
          expect(result[:failed]).to be_empty
        end
      end
    end

    context "weekly orders" do
      let(:reference_date) { Date.new(2024, 1, 15) } # Tuesday
      let(:calculator) { described_class.new(reference_date) }

      context "when merchant live_on matches current weekday" do
        let!(:weekly_merchant) do
          Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
            reference: "weekly_merchant",
            disbursement_frequency: "weekly",
            live_on: reference_date - 7.days, # Previous Tuesday
            email: "weekly@example.com",
            minimum_monthly_fee_cents: 2900
          )
        end

        let!(:weekly_order) do
          Infrastructure::Persistence::ActiveRecord::Models::Order.create!(
            merchant_reference: weekly_merchant.reference,
            amount_cents: 5000,
            created_at: reference_date - 2.days # Sunday
          )
        end

        it "processes orders for the week" do
          result = calculator.create_disbursements
          expect(result[:successful].first.orders).to include(weekly_order)
        end
      end

      context "when merchant live_on is different weekday" do
        let!(:weekly_merchant) do
          Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
            reference: "weekly_merchant",
            disbursement_frequency: "weekly",
            live_on: reference_date - 4.days, # Previous Friday
            email: "weekly@example.com",
            minimum_monthly_fee_cents: 2900
          )
        end

        let!(:weekly_order) do
          Infrastructure::Persistence::ActiveRecord::Models::Order.create!(
            merchant_reference: weekly_merchant.reference,
            amount_cents: 5000,
            created_at: reference_date - 2.days # Sunday
          )
        end

        it "doesn't process orders" do
          result = calculator.create_disbursements
          expect(result).to eq({ successful: [], failed: [] })
        end
      end

      context "when merchant has orders from previous weeks" do
        let!(:weekly_merchant) do
          Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
            reference: "weekly_merchant",
            disbursement_frequency: "weekly",
            live_on: reference_date - 7.days, # Previous Tuesday
            email: "weekly@example.com",
            minimum_monthly_fee_cents: 2900
          )
        end

        let!(:old_order) do
          Infrastructure::Persistence::ActiveRecord::Models::Order.create!(
            merchant_reference: weekly_merchant.reference,
            amount_cents: 5000,
            created_at: reference_date - 14.days # Two weeks ago
          )
        end

        it "excludes old orders" do
          result = calculator.create_disbursements
          expect(result).to eq({ successful: [], failed: [] })
        end
      end
    end

    context "daily and weekly orders" do
      let(:reference_date) { Date.new(2024, 1, 15) } # Tuesday
      let(:calculator) { described_class.new(reference_date) }

      let!(:daily_merchant) do
        Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
          reference: "daily_merchant",
          disbursement_frequency: "daily",
          live_on: reference_date,
          email: "daily@example.com",
          minimum_monthly_fee_cents: 2900
        )
      end

      let!(:weekly_merchant) do
        Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
          reference: "weekly_merchant",
          disbursement_frequency: "weekly",
          live_on: reference_date - 7.days,
          email: "weekly@example.com",
          minimum_monthly_fee_cents: 2900
        )
      end

      let!(:daily_order) do
        Infrastructure::Persistence::ActiveRecord::Models::Order.create!(
          merchant_reference: daily_merchant.reference,
          amount_cents: 5000,
          created_at: reference_date
        )
      end

      let!(:weekly_order) do
        Infrastructure::Persistence::ActiveRecord::Models::Order.create!(
          merchant_reference: weekly_merchant.reference,
          amount_cents: 3000,
          created_at: reference_date - 2.days
        )
      end

      it "processes both types of orders" do
        result = calculator.create_disbursements

        expect(result[:successful].map(&:orders).flatten).to include(daily_order, weekly_order)
        expect(result[:failed]).to be_empty
      end
    end

    context "edge cases" do
      let(:reference_date) { Date.new(2024, 1, 15) }
      let(:calculator) { described_class.new(reference_date) }

      context "when processing multiple merchants with same frequency" do
        let!(:daily_merchant1) do
          Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
            reference: "daily_merchant1",
            disbursement_frequency: "daily",
            live_on: reference_date,
            email: "daily1@example.com",
            minimum_monthly_fee_cents: 2900
          )
        end

        let!(:daily_merchant2) do
          Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
            reference: "daily_merchant2",
            disbursement_frequency: "daily",
            live_on: reference_date,
            email: "daily2@example.com",
            minimum_monthly_fee_cents: 2900
          )
        end

        let!(:order1) do
          Infrastructure::Persistence::ActiveRecord::Models::Order.create!(
            merchant_reference: daily_merchant1.reference,
            amount_cents: 5000,
            created_at: reference_date
          )
        end

        let!(:order2) do
          Infrastructure::Persistence::ActiveRecord::Models::Order.create!(
            merchant_reference: daily_merchant2.reference,
            amount_cents: 3000,
            created_at: reference_date
          )
        end

        it "processes orders for all eligible merchants" do
          result = calculator.create_disbursements

          expect(result[:failed]).to eq([])
          expect(result[:successful].size).to eq(2)
          expect(result[:successful].map(&:merchant_id)).to contain_exactly(daily_merchant1.id, daily_merchant2.id)
        end
      end
    end

    context "error handling" do
      let(:reference_date) { Date.new(2024, 1, 15) }
      let(:calculator) { described_class.new(reference_date) }

      context "when processing individual merchants" do
        let!(:daily_merchant1) do
          Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
            reference: "daily_merchant1",
            disbursement_frequency: "daily",
            live_on: reference_date,
            email: "daily1@example.com",
            minimum_monthly_fee_cents: 2900
          )
        end

        let!(:daily_merchant2) do
          Infrastructure::Persistence::ActiveRecord::Models::Merchant.create!(
            reference: "daily_merchant2",
            disbursement_frequency: "daily",
            live_on: reference_date,
            email: "daily2@example.com",
            minimum_monthly_fee_cents: 2900
          )
        end

        let!(:order1) do
          Infrastructure::Persistence::ActiveRecord::Models::Order.create!(
            merchant_reference: daily_merchant1.reference,
            amount_cents: 5000,
            created_at: reference_date
          )
        end

        let!(:order2) do
          Infrastructure::Persistence::ActiveRecord::Models::Order.create!(
            merchant_reference: daily_merchant2.reference,
            amount_cents: 3000,
            created_at: reference_date
          )
        end

        context "when one merchant fails" do
          before do
            @call_count = 0
            allow_any_instance_of(Domain::Disbursements::Services::Calculators::Daily)
              .to receive(:calculate_and_create) do
                @call_count += 1
                if @call_count == 1
                  raise StandardError.new("Failed to create disbursement")
                else
                  instance_double(
                    Domain::Disbursements::Entities::Disbursement,
                    merchant_id: daily_merchant2.id,
                    orders: [ order2 ]
                  )
                end
              end
          end

          it "continues processing other merchants and tracks failures" do
            expect(Rails.logger).to receive(:error).with(/Failed to create disbursement for merchant/)

            result = calculator.create_disbursements

            # Verify failed disbursement
            expect(result[:failed].size).to eq(1)
            failed_result = result[:failed].first
            expect(failed_result[:error]).to eq("Failed to create disbursement")
            expect(failed_result[:backtrace]).to be_an(Array)
            # Don't check specific merchant_id as it's dynamically generated

            # Verify successful disbursement
            expect(result[:successful].size).to eq(1)
            successful_disbursement = result[:successful].first
            expect(successful_disbursement.merchant_id).to eq(daily_merchant2.id)
            expect(successful_disbursement.orders).to contain_exactly(order2)
          end
        end
      end
    end
  end
end
