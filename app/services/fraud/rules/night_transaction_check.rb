module Fraud
  module Rules
    class NightTransactionCheck < BaseRule
      def call
        return false unless transaction&.created_at
        hour = transaction.created_at.hour
        start_hour = rule.config&.dig("start_hour") || 22
        end_hour = rule.config&.dig("end_hour") || 5

        hour >= start_hour || hour <= end_hour
      end

      def description
        "Night transaction at #{transaction&.created_at}"
      end
    end
  end
end
