require "rake"

module Domain
  module Disbursements
    module Jobs
      class DisbursementCreationJob < ApplicationJob
        queue_as :default

        def perform
          Rails.logger.info "-------------------------------------------------------------------------"
          Rails.logger.info "Starting DisbursementCreationJob at #{Time.current}"
          Rails.application.load_tasks
          ::Rake::Task["disbursements:create"].invoke
          ::Rake::Task["disbursements:create"].reenable
          Rails.logger.info "Finished DisbursementCreationJob at #{Time.current}"
          Rails.logger.info "-------------------------------------------------------------------------"
        end
      end
    end
  end
end
