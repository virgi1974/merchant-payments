# lib/tasks/import.rake

namespace :import do
  MERCHANTS_CSV_PATH = Rails.root.join("db", "data", "merchants.csv").to_s
  ORDERS_CSV_PATH = Rails.root.join("db", "data", "orders.csv").to_s

  desc "Import merchants from CSV file"
  task merchants: :environment do
    Rails.logger.info "Starting import task"
    Domain::Merchants::Services::Importers::CsvImporter.call(MERCHANTS_CSV_PATH)
  end

  desc "Import orders from CSV file"
  task orders: :environment do
    Rails.logger.info "Starting orders import task"
    Domain::Orders::Services::Importers::CsvImporter.call(ORDERS_CSV_PATH)
  end
end
