namespace :monthly_fees do
  desc "Process monthly minimum fees for all merchants for a specific month (default: previous month)"
  task :process, [ :date ] => :environment do |_, args|
    target_date = parse_target_date(args[:date])
    next if target_date.nil?

    if target_date.day != 1
      puts "Skipping monthly fee processing - not first day of month"
      next
    end

    process_monthly_fees(target_date)
  end

  desc "Process monthly fees for a range of past months"
  task :process_historical, [ :start_year ] => :environment do |_, args|
    start_year = (args[:start_year] || 2022).to_i
    end_year = 2023

    unless start_year.between?(2022, end_year)
      puts "Invalid start_year: #{start_year}. Must be between 2022 and #{end_year}"
      next
    end

    puts "Starting historical processing from #{start_year} to #{end_year}"
    total_adjustments = 0

    (start_year..end_year).each do |year|
      12.times do |month|
        target_date = Date.new(year, month + 1, 1)
        break if target_date > Date.current

        puts "\nProcessing #{target_date.strftime("%B %Y")}..."
        process_monthly_fees(target_date)
      end
    end

    puts "\nHistorical processing completed!"
  rescue StandardError => e
    puts "Error in historical processing: #{e.message}"
    raise e
  end

  private

  def process_monthly_fees(target_date)
    puts "Starting monthly fee processing at #{Time.current}"

    previous_month = target_date - 1.month
    merchant_repository = Domain::Fees::Repositories::MerchantRepository.new
    tracker = Domain::Fees::Services::MonthlyFeeTracker.new
    monthly_fees = 0

    puts "Processing fees for #{previous_month.strftime("%B %Y")}"

    merchant_repository.find_all_merchants_in_batches.each do |merchant|
      res = tracker.process_merchant(merchant, previous_month.month, previous_month.year)
      monthly_fees += 1 unless res.nil?
    end

    puts "Finished monthly fee processing at #{Time.current}"
    puts "Monthly Fee Adjustments created: #{monthly_fees}"
  rescue StandardError => e
    puts "Error processing monthly fees: #{e.message}"
    raise e
  end

  def parse_target_date(date_string)
    return Date.current unless date_string

    unless date_string.match?(/\A\d{4}-\d{2}-\d{2}\z/)
      puts "Invalid date format: #{date_string}. Expected format: YYYY-MM-DD"
      return nil
    end

    Date.parse(date_string)
  rescue Date::Error => e
    puts "Invalid date format: #{date_string}. Expected format: YYYY-MM-DD"
    nil
  end
end
