namespace :disbursements do
  desc "Calculate historical disbursements for imported orders"
  task calculate_historical_with_retries: :environment do
    repository = Domain::Disbursements::Repositories::DisbursementRepository.new
    max_retries = 3
    retry_count = 0
    failed_order_history = Hash.new { |h, k| h[k] = [] }
    dates_with_failures = Set.new

    # Get initial date range only once
    date_range = repository.date_range
    return if date_range.min_date.nil?

    start_date = date_range.min_date.to_date
    end_date = date_range.max_date.to_date

    while retry_count <= max_retries
      puts "\nStarting disbursement calculation (Attempt #{retry_count + 1})..."

      # On first attempt, process all dates. After that, only process dates with failures
      dates_to_process = if retry_count == 0
        (start_date..end_date).to_a
      else
        dates_with_failures.to_a
      end

      puts "Processing #{dates_to_process.size} dates..."
      successful_count = 0
      failed_count = 0
      dates_with_failures.clear # Reset for this iteration

      dates_to_process.each do |current_date|
        puts "Processing date: #{current_date}"
        calculator = Domain::Disbursements::Services::DisbursementCalculator.new(current_date)
        results = calculator.create_disbursements

        if results[:failed].any?
          dates_with_failures << current_date
          puts "\nFailures for #{current_date}:"
          results[:failed].each do |failed_order|
            failed_order_history[failed_order[:id]] << {
              attempt: retry_count + 1,
              date: current_date,
              error: failed_order[:errors] || failed_order[:error]
            }
            puts "  Order ##{failed_order[:id]}: #{failed_order[:errors] || failed_order[:error]}"
          end
        end

        successful_count += results[:successful].size
        failed_count += results[:failed].size
        puts "Date: #{current_date} - Success: #{results[:successful].size}, Failed: #{results[:failed].size}"
      end

      puts "\nAttempt #{retry_count + 1} complete!"
      puts "Total successful disbursements: #{successful_count}"
      puts "Total failed disbursements: #{failed_count}"

      break if failed_count == 0
      retry_count += 1
      sleep 2 unless retry_count > max_retries
    end

    print_failure_analysis(failed_order_history) if failed_order_history.any?
  end

  private

  def print_failure_analysis(failed_order_history)
    puts "\nFailure Analysis:"
    failed_order_history.each do |order_id, attempts|
      puts "\nOrder ##{order_id} failure history:"
      attempts.each do |attempt|
        puts "  Attempt #{attempt[:attempt]} on #{attempt[:date]}: #{attempt[:error]}"
      end
    end
  end
end
