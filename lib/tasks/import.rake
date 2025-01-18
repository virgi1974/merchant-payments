# lib/tasks/import.rake

namespace :import do
  MERCHANTS_CSV_PATH = Rails.root.join("db", "data", "merchants.csv").to_s

  desc "Import merchants from CSV file"
  task merchants: :environment do
    Rails.logger.info "Starting import task"
    Domain::Merchants::Services::CsvImporter.call(MERCHANTS_CSV_PATH)
  end
end
