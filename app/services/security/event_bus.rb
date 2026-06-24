module Security
  module EventBus
    EVENTS = {
      login_success: "security.login.success",
      login_failure: "security.login.failure",
      login_blocked: "security.login.blocked",
      logout: "security.logout",
      mfa_success: "security.mfa.success",
      mfa_failure: "security.mfa.failure",
      password_change: "security.password.change",
      password_reset: "security.password.reset",
      account_locked: "security.account.locked",
      account_unlocked: "security.account.unlocked",
      session_revoked: "security.session.revoked",
      permission_denied: "security.authorization.permission_denied",
      suspicious_activity: "security.fraud.suspicious_activity",
      audit_create: "audit.record.create",
      audit_update: "audit.record.update",
      audit_destroy: "audit.record.destroy"
    }.freeze

    def self.publish(event_name, payload = {})
      ActiveSupport::Notifications.instrument(event_name, payload)
    end

    def self.subscribe(event_name, &block)
      ActiveSupport::Notifications.subscribe(event_name, &block)
    end

    def self.subscribe_all(&block)
      EVENTS.each_value do |event|
        ActiveSupport::Notifications.subscribe(event, &block)
      end
    end
  end
end
