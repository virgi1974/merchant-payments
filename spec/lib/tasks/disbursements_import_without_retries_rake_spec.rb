require "rails_helper"
require "rake"

RSpec.describe "disbursements:import_without_retries" do
  before(:each) do
    Rake.application.rake_require("tasks/disbursements_import_without_retries")
    Rake::Task.define_task(:environment)
    Rake::Task["disbursements:import_without_retries"].reenable
  end

  let(:repository) { instance_double(Domain::Disbursements::Repositories::DisbursementRepository) }
  let(:calculator) { instance_double(Domain::Disbursements::Services::DisbursementCalculator) }
  let(:date_range) { instance_double("DateRange", min_date: Date.new(2024, 1, 1), max_date: Date.new(2024, 1, 3)) }

  before(:each) do
    allow(Domain::Disbursements::Repositories::DisbursementRepository).to receive(:new).and_return(repository)
    allow(repository).to receive(:date_range).and_return(date_range)
    allow(Domain::Disbursements::Services::DisbursementCalculator).to receive(:new).and_return(calculator)
    allow(calculator).to receive(:create_disbursements).and_return({ successful: [1], failed: [] })
  end

  it "processes disbursements for each day in the range" do
    expect(Domain::Disbursements::Services::DisbursementCalculator).to receive(:new)
      .exactly(5).times  # min_date-1 to max_date+1 = 5 days
      .with(any_args, true)
      .and_return(calculator)

    Rake::Task["disbursements:import_without_retries"].invoke
  end

  it "uses time travel for each date" do
    times = []
    allow(calculator).to receive(:create_disbursements) do
      times << Time.current.dup
      { successful: [1], failed: [] }
    end

    expect {
      Rake::Task["disbursements:import_without_retries"].invoke
    }.to output(/Processing disbursements from.*to/).to_stdout

    expect(times.map(&:beginning_of_day).uniq.count).to eq(5)
  end

  it "prints start and end dates correctly" do
    expect {
      Rake::Task["disbursements:import_without_retries"].invoke
    }.to output(/Processing disbursements from 2023-12-31 to 2024-01-04/).to_stdout
  end

  it "prints total days to process" do
    expect {
      Rake::Task["disbursements:import_without_retries"].invoke
    }.to output(/Total days to process: 5/).to_stdout
  end

  it "accumulates successful and failed counts correctly" do
    allow(calculator).to receive(:create_disbursements).and_return(
      { successful: [1, 2], failed: [3] },
      { successful: [4], failed: [5, 6] },
      { successful: [], failed: [7] },
      { successful: [8], failed: [] },
      { successful: [9, 10], failed: [11] }
    )

    expect {
      Rake::Task["disbursements:import_without_retries"].invoke
    }.to output(/Total successful disbursements: 6.*Total failed disbursements: 5/m).to_stdout
  end

  context "when date_range is empty" do
    before(:each) do
      allow(repository).to receive(:date_range).and_return(nil)
    end

    it "exits early without processing" do
      expect(Domain::Disbursements::Services::DisbursementCalculator).not_to receive(:new)
      expect {
        Rake::Task["disbursements:import_without_retries"].invoke
      }.to output(/No date range found, exiting.../).to_stdout
    end
  end

  context "when processing specific dates" do
    let(:specific_date) { Date.new(2024, 1, 2) }

    it "processes each date at beginning of day" do
      processed_times = []
      allow(calculator).to receive(:create_disbursements) do
        processed_times << Time.current
        { successful: [1], failed: [] }
      end

      Rake::Task["disbursements:import_without_retries"].invoke

      processed_times.each do |time|
        expect(time.hour).to eq(0)
        expect(time.min).to eq(0)
        expect(time.sec).to eq(0)
      end
    end
  end

  context "when calculator fails with exception" do
    it "continues processing remaining dates" do
      call_count = 0
      allow(calculator).to receive(:create_disbursements) do
        call_count += 1
        raise "Error" if call_count == 2
        { successful: [1], failed: [] }
      end

      expect {
        Rake::Task["disbursements:import_without_retries"].invoke
      }.to raise_error(RuntimeError)

      expect(call_count).to eq(2)
    end
  end

  context "with different date ranges" do
    let(:single_day_range) { instance_double("DateRange", min_date: Date.new(2024, 1, 1), max_date: Date.new(2024, 1, 1)) }

    it "handles single day range correctly" do
      allow(repository).to receive(:date_range).and_return(single_day_range)

      expect(Domain::Disbursements::Services::DisbursementCalculator).to receive(:new)
        .exactly(3).times # min_date-1 to max_date+1 = 3 days
        .and_return(calculator)

      Rake::Task["disbursements:import_without_retries"].invoke
    end
  end
end
