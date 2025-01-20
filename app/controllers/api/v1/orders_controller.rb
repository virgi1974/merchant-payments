module Api
  module V1
    class OrdersController < ApplicationController
      OrderPresenter = Infrastructure::Presenters::Api::V1::OrderPresenter

      rescue_from StandardError do |e|
        case e
        when ActionController::ParameterMissing
          render OrderPresenter.error("Missing required parameters: #{e.param}", :unprocessable_entity)
        when Domain::Orders::Errors::ValidationError
          render OrderPresenter.error("Invalid order data: #{e.message}", :unprocessable_entity)
        when ActiveRecord::RecordInvalid
          render OrderPresenter.error("Invalid data: #{e.message}", :unprocessable_entity)
        when ActiveRecord::RecordNotUnique
          render OrderPresenter.error("Order already exists", :conflict)
        else
          error_details = {
            exception: e.class.name,
            message: e.message,
            backtrace: e.backtrace.first(5)
          }
          Rails.logger.error("Unexpected error in order creation: #{error_details}")
          render OrderPresenter.error("Something went wrong", :internal_server_error)
        end
      end

      def create
        order = Domain::Orders::Services::ApiImporter.call(order_params.to_h)
        render OrderPresenter.created(order)
      end

      private

      def order_params
        params.permit([
          :merchant_reference,
          :amount,
          :created_at
        ])
      end
    end
  end
end
