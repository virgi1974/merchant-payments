namespace :disbursements do
  desc "Create daily disbursements for a specific date (defaults to current date)"
  task :create, [ :date ] => :environment do |_t, args|
    date = if args[:date]
             Date.parse(args[:date])
    else
             Date.current
    end

    calculator = Domain::Disbursements::Services::DisbursementCalculator.new(date)
    results = calculator.create_disbursements

    Rails.logger.info "Created #{results[:successful].count} disbursements for #{date}"
    Rails.logger.error "Failed #{results[:failed].count} disbursements" if results[:failed].any?
  end
end
