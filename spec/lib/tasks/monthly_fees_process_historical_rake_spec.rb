require "rails_helper"
require "rake"

RSpec.describe "monthly_fees:process_historical" do
  include ActiveSupport::Testing::TimeHelpers

  before do
    Rake.application.rake_require("tasks/monthly_fees")
    Rake::Task.define_task(:environment)
  end

  let(:task) { Rake::Task["monthly_fees:process_historical"] }
  let(:merchant) { double("Merchant", reference: "TEST001") }
  let(:merchant_repository) { double("MerchantRepository") }
  let(:tracker) { double("MonthlyFeeTracker") }

  before do
    allow(Domain::Fees::Repositories::MerchantRepository).to receive(:new).and_return(merchant_repository)
    allow(Domain::Fees::Services::MonthlyFeeTracker).to receive(:new).and_return(tracker)
    allow(merchant_repository).to receive(:find_all_merchants_in_batches).and_return([ merchant ])
    allow(tracker).to receive(:process_merchant).and_return(true)
  end

  describe "process_historical" do
    context "with invalid start_year" do
      it "exits with error message when start_year is before 2022" do
        expect { task.execute(start_year: "2021") }.to output(
          /Invalid start_year: 2021. Must be between 2022 and 2023/
        ).to_stdout
      end

      it "exits with error message when start_year is after end_year" do
        expect { task.execute(start_year: "2024") }.to output(
          /Invalid start_year: 2024. Must be between 2022 and 2023/
        ).to_stdout
      end
    end

    context "with valid start_year" do
      it "processes fees for all months until current date" do
        travel_to Time.zone.local(2022, 3, 1) do
          expect { task.execute(start_year: "2022") }.to output(
            /Starting historical processing.*Processing January 2022.*Processing February 2022.*Historical processing completed!/m
          ).to_stdout
        end
      end

      it "stops at current date" do
        travel_to Time.zone.local(2022, 2, 1) do
          expect { task.execute(start_year: "2022") }.not_to output(
            /Processing March 2022/
          ).to_stdout
        end
      end
    end
  end
end
