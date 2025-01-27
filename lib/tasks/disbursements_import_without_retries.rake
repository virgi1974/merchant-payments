namespace :disbursements do
  desc "Calculate historical disbursements for imported orders"
  task import_without_retries: :environment do
    require "active_support/testing/time_helpers"
    include ActiveSupport::Testing::TimeHelpers

    repository = Domain::Disbursements::Repositories::DisbursementRepository.new
    date_range = repository.date_range

    if date_range.nil?
      puts "No date range found, exiting..."
      next
    end

    start_date = date_range.min_date.to_date - 1.day
    end_date = date_range.max_date.to_date + 1.day

    puts "Starting historical disbursement calculation..."
    puts "time: #{Time.current}"
    puts "Processing disbursements from #{start_date} to #{end_date}"
    puts "Total days to process: #{(end_date - start_date).to_i + 1}"

    current_date = start_date
    successful_count = 0
    failed_count = 0

    while current_date <= end_date
      travel_to(current_date.beginning_of_day) do
        puts "Processing date: #{current_date}"
        calculator = Domain::Disbursements::Services::DisbursementCalculator.new(current_date, true)
        results = calculator.create_disbursements

        successful_count += results[:successful].size
        failed_count += results[:failed].size
        puts "Date: #{current_date} - Success: #{results[:successful].size}, Failed: #{results[:failed].size}"
      end

      current_date += 1.day
    end

    puts "\nProcessing complete!"
    puts "time: #{Time.current}"
    puts "Total successful disbursements: #{successful_count}"
    puts "Total failed disbursements: #{failed_count}"
  end
end
