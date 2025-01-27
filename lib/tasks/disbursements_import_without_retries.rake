namespace :disbursements do
  desc "Calculate historical disbursements for imported orders"
  task import: :calculate_historical_without_retries do
    repository = Domain::Disbursements::Repositories::DisbursementRepository.new
    date_range = repository.date_range

    start_date = date_range.min_date.to_date
    end_date = date_range.max_date.to_date

    return if start_date.nil?

    puts "Starting historical disbursement calculation..."
    puts "time: #{Time.current}"
    puts "Processing disbursements from #{start_date} to #{end_date}"
    puts "Total days to process: #{(end_date - start_date).to_i + 1}"

    current_date = start_date
    successful_count = 0
    failed_count = 0

    while current_date <= end_date
      puts "Processing date: #{current_date}"
      calculator = Domain::Disbursements::Services::DisbursementCalculator.new(current_date)
      results = calculator.create_disbursements

      successful_count += results[:successful].size
      failed_count += results[:failed].size
      puts "Date: #{current_date} - Success: #{results[:successful].size}, Failed: #{results[:failed].size}"

      current_date += 1.day
    end

    puts "\nProcessing complete!"
    puts "time: #{Time.current}"
    puts "Total successful disbursements: #{successful_count}"
    puts "Total failed disbursements: #{failed_count}"
  end
end
