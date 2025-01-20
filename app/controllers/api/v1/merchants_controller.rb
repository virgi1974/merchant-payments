module Api
  module V1
    class MerchantsController < ApplicationController
      MerchantPresenter = Infrastructure::Presenters::Api::V1::MerchantPresenter

      rescue_from StandardError do |e|
        case e
        when ActionController::ParameterMissing
          render MerchantPresenter.error("Missing required parameters: #{e.param}", :unprocessable_entity)
        when Domain::Merchants::Errors::ValidationError
          render MerchantPresenter.error("Invalid merchant data: #{e.message}", :unprocessable_entity)
        when ActiveRecord::RecordInvalid
          render MerchantPresenter.error("Invalid data: #{e.message}", :unprocessable_entity)
        when ActiveRecord::RecordNotUnique
          render MerchantPresenter.error("Merchant already exists", :conflict)
        else
          error_details = {
            exception: e.class.name,
            message: e.message,
            backtrace: e.backtrace.first(5)
          }
          Rails.logger.error("Unexpected error in merchant creation: #{error_details}")
          render MerchantPresenter.error("Something went wrong", :internal_server_error)
        end
      end

      def create
        merchant = Domain::Merchants::Services::ApiImporter.call(merchant_params.to_h)
        render MerchantPresenter.created(merchant)
      end

      private

      def merchant_params
        params.permit([
          :reference,
          :email,
          :live_on,
          :disbursement_frequency,
          :minimum_monthly_fee
        ])
      end
    end
  end
end
