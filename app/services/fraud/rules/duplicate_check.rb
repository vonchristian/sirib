module Fraud
  module Rules
    class DuplicateCheck < BaseRule
      def call
        return false unless transaction
        window = (rule.config&.dig("window_minutes")&.minutes) || 5.minutes

        Accounting::Entry
          .where(description: transaction.description)
          .where("created_at > ?", window.ago)
          .exists?
      end

      def description
        "Duplicate transaction detected"
      end
    end
  end
end
