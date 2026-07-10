module Fraud
  module Rules
    class VelocityCheck < BaseRule
      def call
        return false unless account
        threshold = rule.config&.dig("threshold") || 10
        window = (rule.config&.dig("window_minutes")&.minutes) || 1.hour

        count = Accounting::Entry
          .joins(:amount_lines)
          .where(amount_lines: { account_id: account.id })
          .where("entries.created_at > ?", window.ago)
          .count

        count >= threshold
      end

      def description
        window = (rule.config&.dig("window_minutes")&.minutes) || 1.hour
        threshold = rule.config&.dig("threshold") || 10
        "#{threshold}+ transactions in #{window.inspect}"
      end
    end
  end
end
