module Fraud
  module Rules
    class HighRiskCategory < BaseRule
      def call
        return false unless transaction
        categories = rule.config&.dig("risk_categories") || []
        return false unless transaction.respond_to?(:category)

        categories.include?(transaction.category)
      end

      def description
        "Transaction category is high risk"
      end
    end
  end
end
