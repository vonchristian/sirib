module Fraud
  class RuleEngine
    def self.evaluate(transaction: nil, account: nil, user: nil, cooperative: nil)
      new.evaluate(transaction:, account:, user:, cooperative:)
    end

    def evaluate(transaction: nil, account: nil, user: nil, cooperative: nil)
      flags = []
      rules = Fraud::Rule.where(active: true)

      if cooperative
        rules = rules.where(cooperative: cooperative)
      end

      rules.find_each do |rule|
        result = evaluate_rule(rule, transaction:, account:, user:)
        flags.concat(result) if result.any?
      end

      flags
    end

    private

    def evaluate_rule(rule, transaction: nil, account: nil, user: nil)
      case rule.rule_type
      when "large_amount" then check_large_amount(rule, transaction)
      when "unusual_frequency" then check_frequency(rule, account)
      when "rapid_transfers" then check_rapid_transfers(rule, account)
      when "impossible_travel" then check_impossible_travel(rule, user)
      when "dormant_account" then check_dormant_account(rule, account)
      when "night_transactions" then check_night_transactions(rule, transaction)
      when "duplicate_transaction" then check_duplicate(rule, transaction)
      when "multiple_ips" then check_multiple_ips(rule, user)
      when "custom" then check_custom(rule, transaction:, account:, user:)
      else []
      end
    end

    def check_large_amount(rule, transaction)
      return [] unless transaction
      threshold = rule.config&.dig("threshold_cents") || 10_000_00
      return [] unless transaction.amount_cents.to_i > threshold

      create_incident(rule, "Large transaction: #{transaction.amount_cents} cents", severity: rule.severity)
    end

    def check_frequency(rule, account)
      return [] unless account
      threshold = rule.config&.dig("threshold") || 10
      window = rule.config&.dig("window_minutes")&.minutes || 1.hour

      count = Accounting::Entry
        .joins(:amount_lines)
        .where(amount_lines: { account_id: account.id })
        .where("entries.created_at > ?", window.ago)
        .count

      return [] unless count >= threshold

      create_incident(rule, "#{count} transactions in #{window.inspect}", severity: rule.severity)
    end

    def check_rapid_transfers(rule, account)
      return [] unless account
      threshold = rule.config&.dig("threshold") || 5
      window = rule.config&.dig("window_minutes")&.minutes || 5.minutes

      count = Accounting::Entry
        .joins(:amount_lines)
        .where(amount_lines: { account_id: account.id })
        .where("entries.created_at > ?", window.ago)
        .count

      return [] unless count >= threshold

      create_incident(rule, "#{count} rapid transfers in #{window.inspect}", severity: rule.severity)
    end

    def check_impossible_travel(rule, user)
      return [] unless user
      threshold_km = rule.config&.dig("threshold_km") || 100

      recent_sessions = user.sessions.active.where.not(ip_address: nil).order(created_at: :desc).limit(2)
      return [] unless recent_sessions.size >= 2

      locations = recent_sessions.map { |s| geolocate(s.ip_address) }.compact
      return [] unless locations.size >= 2

      distance = haversine_distance(locations[0], locations[1])
      return [] unless distance > threshold_km

      time_diff = (recent_sessions[0].created_at - recent_sessions[1].created_at).abs
      return [] unless time_diff < 1.hour

      create_incident(rule, "Impossible travel: #{distance.round}km in #{time_diff.round}s", severity: rule.severity)
    end

    def check_dormant_account(rule, account)
      return [] unless account
      days_threshold = rule.config&.dig("days_threshold") || 90

      last_activity = Accounting::Entry
        .joins(:amount_lines)
        .where(amount_lines: { account_id: account.id })
        .maximum(:created_at)

      return [] unless last_activity
      return [] unless last_activity < days_threshold.days.ago

      create_incident(rule, "Dormant account activity after #{((Time.current - last_activity) / 1.day).round} days", severity: rule.severity)
    end

    def check_night_transactions(rule, transaction)
      return [] unless transaction&.created_at
      hour = transaction.created_at.hour
      start_hour = rule.config&.dig("start_hour") || 22
      end_hour = rule.config&.dig("end_hour") || 5

      return [] unless hour >= start_hour || hour <= end_hour

      create_incident(rule, "Night transaction at #{transaction.created_at}", severity: rule.severity)
    end

    def check_duplicate(rule, transaction)
      return [] unless transaction
      window = rule.config&.dig("window_minutes")&.minutes || 5.minutes

      duplicate = Accounting::Entry
        .where(description: transaction.description)
        .where("created_at > ?", window.ago)
        .exists?

      return [] unless duplicate

      create_incident(rule, "Duplicate transaction detected", severity: rule.severity)
    end

    def check_multiple_ips(rule, user)
      return [] unless user
      threshold = rule.config&.dig("threshold") || 3
      window = rule.config&.dig("window_minutes")&.minutes || 24.hours

      ip_count = user.sessions.active
        .where("created_at > ?", window.ago)
        .where.not(ip_address: nil)
        .distinct
        .count(:ip_address)

      return [] unless ip_count >= threshold

      create_incident(rule, "#{ip_count} different IPs in #{window.inspect}", severity: rule.severity)
    end

    def check_custom(rule, transaction: nil, account: nil, user: nil)
      return [] unless rule.config&.dig("check").present?

      begin
        result = eval(rule.config["check"], binding, __FILE__, __LINE__)
        result ? create_incident(rule, "Custom rule matched", severity: rule.severity) : []
      rescue => e
        Rails.logger.error "Custom fraud rule '#{rule.name}' failed: #{e.message}"
        []
      end
    end

    def create_incident(rule, description, severity: "medium")
      [ {
        rule_id: rule.id,
        rule_name: rule.name,
        description: description,
        severity: severity
      } ]
    end

    def geolocate(ip)
      return nil if ip.blank? || ip == "127.0.0.1" || ip == "::1"

      nil
    end

    def haversine_distance(loc1, loc2)
      0
    end
  end
end
