require "rails_helper"
require "rake"

RSpec.describe "import:merchants" do
  before do
    Rails.application.load_tasks  # Load all rake tasks
    Rake::Task.define_task(:environment)
  end

  let(:csv_path) { Rails.root.join("db", "data", "merchants.csv").to_s }
  let(:importer) { Domain::Merchants::Services::Importers::CsvImporter }

  it "calls the CsvImporter service with the correct path" do
    expect(importer).to receive(:call).with(csv_path)
    Rake::Task["import:merchants"].invoke
  end
end
