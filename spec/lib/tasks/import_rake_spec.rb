require "rails_helper"

RSpec.describe "import:merchants" do
  include_context "rake"

  before do
    Rake.application.rake_require("import", [ Rails.root.join("lib/tasks").to_s ])
  end

  let(:csv_path) { Rails.root.join("db", "data", "merchants.csv").to_s }
  let(:importer) { Domain::Merchants::Services::Importers::CsvImporter }

  it "calls the CsvImporter service with the correct path" do
    expect(importer).to receive(:call).with(csv_path).once
    Rake::Task["import:merchants"].invoke
  end
end
