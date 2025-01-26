namespace :monthly_fees do
  desc "Process monthly minimum fees for all merchants for the previous month"
  task process: :environment do
    Rails.logger.info "Starting monthly fee processing at #{Time.current}"
    monthly_fees = 0  # Add counter

    today = Date.current
    unless today.day == 1
      Rails.logger.info "Skipping monthly fee processing - not first day of month"
      next
    end

    previous_month = today - 1.month
    merchant_repository = Domain::Fees::Repositories::MerchantRepository.new
    tracker = Domain::Disbursements::Services::MonthlyFeeTracker.new(merchant_repository)

    Rails.logger.info "Processing fees for #{previous_month.strftime("%B %Y")}"

    begin
      merchant_repository.find_all_merchants_in_batches.each do |merchant|
        Rails.logger.info "Processing merchant #{merchant.reference}"
        res = tracker.process_merchant(merchant, previous_month.month, previous_month.year)
        monthly_fees += 1 unless res.nil?  # Track successful adjustments
      rescue StandardError => e
        Rails.logger.error "Error processing merchant #{merchant.reference}: #{e.message}"
        next  # Continue with next merchant instead of failing entire batch
      end

      Rails.logger.info "Finished monthly fee processing at #{Time.current}"
      Rails.logger.info "Monthly Fee Adjustments created: #{monthly_fees}"
    rescue StandardError => e
      Rails.logger.error "Error processing monthly fees: #{e.message}"
      raise e
    end
  end
end
