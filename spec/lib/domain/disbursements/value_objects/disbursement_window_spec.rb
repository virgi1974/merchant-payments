require "rails_helper"

module Domain
  module Disbursements
    module ValueObjects
      RSpec.describe DisbursementWindow do
        let(:reference_date) { Date.new(2024, 1, 15) } # A Tuesday

        describe "#start_time" do
          context "with daily frequency" do
            let(:window) { described_class.new(reference_date, "daily") }

            it "returns beginning of current day in UTC" do
              expect(window.start_time).to eq(reference_date.beginning_of_day.utc)
            end
          end

          context "with weekly frequency" do
            let(:window) { described_class.new(reference_date, "weekly") }

            it "returns beginning of day 6 days ago in UTC" do
              expected_start = (reference_date - 6.days).beginning_of_day.utc
              expect(window.start_time).to eq(expected_start)
            end
          end

          context "with invalid frequency" do
            let(:window) { described_class.new(reference_date, "monthly") }

            it "raises an error" do
              expect { window.start_time }.to raise_error(
                ArgumentError,
                "Unknown frequency: monthly"
              )
            end
          end
        end

        describe "#end_time" do
          let(:window) { described_class.new(reference_date, "daily") }

          it "returns end of current day in UTC" do
            expect(window.end_time).to eq(reference_date.end_of_day.utc)
          end

          it "is independent of frequency" do
            daily_window = described_class.new(reference_date, "daily")
            weekly_window = described_class.new(reference_date, "weekly")

            expect(daily_window.end_time).to eq(weekly_window.end_time)
          end
        end
      end
    end
  end
end
