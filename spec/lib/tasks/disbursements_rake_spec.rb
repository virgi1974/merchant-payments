require "rails_helper"

RSpec.describe "disbursements:create" do
  include_context "rake"

  let(:calculator) { instance_double(Domain::Disbursements::Services::DisbursementCalculator) }
  let(:date) { Date.new(2024, 1, 1) }

  before do
    Rake.application.rake_require("disbursements", [ Rails.root.join("lib/tasks").to_s ])
  end

  it "creates disbursements with calculator" do
    expect(Domain::Disbursements::Services::DisbursementCalculator).to receive(:new)
      .with(date)
      .and_return(calculator)
    expect(calculator).to receive(:create_disbursements)
      .and_return({ successful: [], failed: [] })

    Rake::Task["disbursements:create"].invoke("2024-01-01")
  end
end
