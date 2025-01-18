module Domain
  module Merchants
    module Services
      class CreateMerchant
        # TODO: Service responsibilities:
        # 1. Validate input data
        # 2. Generate UUID if not provided
        # 3. Convert disbursement_frequency from string (DAILY/WEEKLY) to symbol (:daily/:weekly)
        # 4. Convert minimum_monthly_fee to cents for Money gem
        # 5. Create ActiveRecord merchant
        # 6. Return Domain::Merchants::Merchant entity

        def self.call(params)
          new(params).call
        end

        def initialize(params)
          @params = params
        end

        def call
          # TODO: Implementation steps
          # 1. Normalize params
          #    - Convert DAILY/WEEKLY to lowercase symbol
          #    - Convert minimum_monthly_fee to cents

          # 2. Create AR record
          #    merchant_record = Infrastructure::Persistence::ActiveRecord::Merchant.create!(
          #      normalized_params
          #    )

          # 3. Return domain entity
          #    Domain::Merchants::Merchant.new(
          #      merchant_record.attributes
          #    )
        rescue ActiveRecord::RecordInvalid => e
          # TODO: Handle validation errors
        end

        private

        attr_reader :params

        def normalize_params
          # TODO: Transform params to match AR model requirements
        end
      end
    end
  end
end
