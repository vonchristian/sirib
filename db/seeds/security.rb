puts "  Seeding security configuration..."

Cooperative.active.order(:name).each do |coop|
  puts "    Cooperative: #{coop.name}"

  Security::PasswordPolicy.find_or_create_by!(
    name: "Default Policy",
    cooperative: coop
  ) do |p|
    p.min_length = 8
    p.require_uppercase = true
    p.require_lowercase = true
    p.require_digits = true
    p.require_symbols = false
    p.max_failed_attempts = 10
    p.lockout_duration = 30
    p.password_expiry_days = 90
    p.password_history_count = 5
    p.active = true
    puts "      Created default password policy"
  end

  Fraud::Rule.find_or_create_by!(
    name: "Large Transaction Alert",
    cooperative: coop
  ) do |r|
    r.rule_type = "large_amount"
    r.severity = "medium"
    r.active = true
    r.config = { "threshold_cents" => 1_000_000_00 }
    r.description = "Flags transactions exceeding PHP 1,000,000"
    puts "      Created fraud rule: Large Transaction Alert"
  end

  Fraud::Rule.find_or_create_by!(
    name: "Unusual Frequency Detection",
    cooperative: coop
  ) do |r|
    r.rule_type = "unusual_frequency"
    r.severity = "medium"
    r.active = true
    r.config = { "threshold" => 10, "window_minutes" => 60 }
    r.description = "Flags accounts with 10+ transactions in an hour"
    puts "      Created fraud rule: Unusual Frequency Detection"
  end

  Fraud::Rule.find_or_create_by!(
    name: "Rapid Transfer Detection",
    cooperative: coop
  ) do |r|
    r.rule_type = "rapid_transfers"
    r.severity = "high"
    r.active = true
    r.config = { "threshold" => 5, "window_minutes" => 5 }
    r.description = "Flags 5+ transfers within 5 minutes"
    puts "      Created fraud rule: Rapid Transfer Detection"
  end

  Fraud::Rule.find_or_create_by!(
    name: "Night Transaction Monitoring",
    cooperative: coop
  ) do |r|
    r.rule_type = "night_transactions"
    r.severity = "low"
    r.active = true
    r.config = { "start_hour" => 22, "end_hour" => 5 }
    r.description = "Flags transactions between 10 PM and 5 AM"
    puts "      Created fraud rule: Night Transaction Monitoring"
  end

  Fraud::Rule.find_or_create_by!(
    name: "Duplicate Transaction Detection",
    cooperative: coop
  ) do |r|
    r.rule_type = "duplicate_transaction"
    r.severity = "high"
    r.active = true
    r.config = { "window_minutes" => 5 }
    r.description = "Flags transactions with identical descriptions within 5 minutes"
    puts "      Created fraud rule: Duplicate Transaction Detection"
  end

  %w[authentication authorization encryption audit logging security fraud].each do |category|
    Compliance::Control.find_or_create_by!(
      name: "#{category.humanize} Compliance Check",
      cooperative: coop
    ) do |c|
      c.category = category
      c.frequency = category == "authentication" ? "daily" : "weekly"
      c.active = true
      c.config = {}
      c.description = "Automated compliance check for #{category}"
    end
  end
  puts "      Created compliance controls"
end

puts "  Security seeding complete."
