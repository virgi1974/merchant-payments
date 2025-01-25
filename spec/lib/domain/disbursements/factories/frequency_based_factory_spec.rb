require "rails_helper"

module Domain
  module Disbursements
    module Factories
      RSpec.describe FrequencyBasedFactory do
        let(:merchant) { instance_double("Merchant") }
        let(:date) { Date.new(2024, 1, 15) }
        let(:repository) { instance_double("OrderRepository") }

        describe ".create" do
          context "with daily frequency" do
            let(:frequency) { "daily" }

            it "returns a daily calculator instance" do
              calculator = described_class.create(frequency, merchant, date, repository)
              expect(calculator).to be_a(Domain::Disbursements::Services::Calculators::Daily)
            end
          end

          context "with weekly frequency" do
            let(:frequency) { "weekly" }

            it "returns a weekly calculator instance" do
              calculator = described_class.create(frequency, merchant, date, repository)
              expect(calculator).to be_a(Domain::Disbursements::Services::Calculators::Weekly)
            end
          end

          context "with invalid frequency" do
            let(:frequency) { "monthly" }

            it "raises an error" do
              expect {
                described_class.create(frequency, merchant, date, repository)
              }.to raise_error(
                Domain::Disbursements::Errors::InvalidFrequencyError,
                "Unknown frequency: monthly"
              )
            end
          end

          it "passes all arguments to calculator" do
            frequency = "daily"
            calculator_class = Domain::Disbursements::Services::Calculators::Daily

            expect(calculator_class).to receive(:new)
              .with(merchant, date, repository)
              .and_call_original

            described_class.create(frequency, merchant, date, repository)
          end
        end
      end
    end
  end
end
