module Fraud
  module Rules
    class DormantAccountCheck < BaseRule
      def call
        return false unless account
        days_threshold = rule.config&.dig("days_threshold") || 90

        last_activity = Accounting::Entry
          .joins(:amount_lines)
          .where(amount_lines: { account_id: account.id })
          .maximum(:created_at)

        return false unless last_activity
        last_activity < days_threshold.days.ago
      end

      def description
        days_threshold = rule.config&.dig("days_threshold") || 90
        "Dormant account activity after #{days_threshold} days"
      end
    end
  end
end
