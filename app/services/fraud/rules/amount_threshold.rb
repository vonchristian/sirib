module Fraud
  module Rules
    class AmountThreshold < BaseRule
      def call
        return false unless transaction
        threshold_cents = rule.config&.dig("threshold_cents") || 10_000_00
        transaction.amount_cents.to_i > threshold_cents
      end

      def description
        "Large transaction: #{transaction&.amount_cents} cents"
      end
    end
  end
end
