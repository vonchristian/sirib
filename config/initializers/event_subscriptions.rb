Rails.application.reloader.to_prepare do
  ActiveSupport::Notifications.subscribe("security.login.success") do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    Rails.logger.info "[SECURITY] Login success: user_id=#{event.payload[:user_id]} ip=#{event.payload[:ip]}"
  end

  ActiveSupport::Notifications.subscribe("security.login.failure") do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    Rails.logger.warn "[SECURITY] Login failure: user_id=#{event.payload[:user_id]} ip=#{event.payload[:ip]}"
  end

  ActiveSupport::Notifications.subscribe("security.account.locked") do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    Rails.logger.warn "[SECURITY] Account locked: user_id=#{event.payload[:user_id]}"

    Fraud::Incident.create!(
      rule: Fraud::Rule.where(rule_type: "brute_force", active: true).first || Fraud::Rule.create!(
        name: "Brute Force Detection",
        rule_type: "brute_force",
        severity: "high",
        active: true,
        cooperative: event.payload[:cooperative]
      ),
      incident_type: "account_locked",
      severity: "high",
      description: "Account locked due to multiple failed login attempts",
      metadata: event.payload,
      actor: User.find_by(id: event.payload[:user_id]),
      cooperative: event.payload[:cooperative]
    )
  end

  ActiveSupport::Notifications.subscribe("security.fraud.suspicious_activity") do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    Rails.logger.warn "[FRAUD] Suspicious activity detected: #{event.payload[:description]}"
  end
end
