module Domain
  module Fees
    module Jobs
      class MonthlyFeeProcessingJob < ApplicationJob
        queue_as :default

        def perform
          Rails.logger.info "-------------------------------------------------------------------------"
          Rails.logger.info "Starting MonthlyFeeProcessingJob at #{Time.current}"
          Rails.application.load_tasks
          ::Rake::Task["monthly_fees:process"].invoke
          ::Rake::Task["monthly_fees:process"].reenable
          Rails.logger.info "Finished MonthlyFeeProcessingJob at #{Time.current}"
          Rails.logger.info "-------------------------------------------------------------------------"
        end
      end
    end
  end
end
