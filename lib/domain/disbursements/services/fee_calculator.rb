module Domain
  module Disbursements
    module Services
      class FeeCalculator
        FEE_TIERS = {
          (0...5000) => 0.01,             # 1.0% for amounts < 50€
          (5000..30000) => 0.0095,        # 0.95% for amounts 50€ - 300€
          (30000..) => 0.0085             # 0.85% for amounts >= 300€
        }.freeze

        def calculate_total_fees(orders)
          orders.sum { |order| calculate_fee(order.amount_cents) }
        end

        private

        def calculate_fee(amount_cents)
          fee_percentage = FEE_TIERS.find { |range, _| range.include?(amount_cents) }&.last
          (amount_cents * fee_percentage).round
        end
      end
    end
  end
end
