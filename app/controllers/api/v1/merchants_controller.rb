module Api
  module V1
    class MerchantsController < ApplicationController
      MerchantPresenter = Infrastructure::Presenters::Api::V1::MerchantPresenter

      def create
        merchant = Domain::Merchants::Services::ApiImporter.call(merchant_params.to_h)
        render MerchantPresenter.created(merchant)
      rescue Domain::Merchants::Errors::ValidationError => e
        render MerchantPresenter.error(e.message, :unprocessable_entity)
      rescue ActiveRecord::RecordInvalid => e
        render MerchantPresenter.error("Invalid data: #{e.message}", :unprocessable_entity)
      rescue ActiveRecord::RecordNotUnique => e
        render MerchantPresenter.error("Merchant already exists", :conflict)
      rescue StandardError => e
        Rails.logger.error("Unexpected error in merchant creation: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        render MerchantPresenter.error("Something went wrong", :internal_server_error)
      end

      private

      def merchant_params
        params.require(:merchant).permit(
          :id,
          :reference,
          :email,
          :live_on,
          :disbursement_frequency,
          :minimum_monthly_fee
        )
      rescue ActionController::ParameterMissing
        raise Domain::Merchants::Errors::ValidationError, "Missing merchant data"
      end
    end
  end
end
