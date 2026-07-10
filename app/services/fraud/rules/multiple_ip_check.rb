module Fraud
  module Rules
    class MultipleIpCheck < BaseRule
      def call
        return false unless user
        threshold = rule.config&.dig("threshold") || 3
        window = (rule.config&.dig("window_minutes")&.minutes) || 24.hours

        ip_count = user.sessions.active
          .where("created_at > ?", window.ago)
          .where.not(ip_address: nil)
          .distinct
          .count(:ip_address)

        ip_count >= threshold
      end

      def description
        threshold = rule.config&.dig("threshold") || 3
        window = (rule.config&.dig("window_minutes")&.minutes) || 24.hours
        "#{threshold}+ different IPs in #{window.inspect}"
      end
    end
  end
end
