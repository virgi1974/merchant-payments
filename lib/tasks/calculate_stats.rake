namespace :stats do
  desc "Calculate disbursement statistics for README table"
  task calculate_table_data: [ :environment ] do
    # First ensure we have all historical monthly fees
    Rake::Task["monthly_fees:process_historical"].invoke

    disbursement_repository = Domain::Disbursements::Repositories::DisbursementRepository.new
    monthly_fee_repository = Domain::Fees::Repositories::MonthlyFeeRepository.new

    results = (2022..2023).each_with_object({}) do |year, stats|
      yearly_disbursements = disbursement_repository.for_year(year)

      stats[year] = {
        disbursements: yearly_disbursements[:size],
        amount_disbursed: yearly_disbursements[:sum_amount] / 100.0,
        fees: yearly_disbursements[:sum_fees] / 100.0,
        monthly_fees_count: monthly_fee_repository.count_for_year(year),
        monthly_fees_amount: monthly_fee_repository.sum_amount_for_year(year) / 100.0
      }
    end

    print_table(results)
  end

  private

  def print_table(results)
    puts "| Year | Number of disbursements | Amount disbursed to merchants | Amount of order fees | Number of monthly fees charged | Amount of monthly fee charged |"
    puts "|------|------------------------|----------------------------|--------------------|-----------------------------|----------------------------|"

    results.each do |year, data|
      puts "| #{year} | #{data[:disbursements]} | "\
           "#{data[:amount_disbursed].round(2)} € | "\
           "#{data[:fees].round(2)} € | "\
           "#{data[:monthly_fees_count]} | "\
           "#{data[:monthly_fees_amount].round(2)} € |"
    end
  end
end
