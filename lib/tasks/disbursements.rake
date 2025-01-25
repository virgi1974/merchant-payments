# lib/tasks/disbursements.rake
namespace :disbursements do
  desc "Process daily disbursements"
  task process: :environment do
    calculator = Domain::Disbursements::Services::DisbursementCalculator.new
    disbursements = calculator.create_disbursements

    Rails.logger.info "Processed #{disbursements.count} disbursements"
  end
end
