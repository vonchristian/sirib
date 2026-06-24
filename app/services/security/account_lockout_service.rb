module Security
  class AccountLockoutService
    def self.record_failed_attempt!(user)
      user.increment!(:failed_attempts)

      policy = PasswordPolicyService.active_policy(user.cooperative)
      max_attempts = policy[:max_failed_attempts]

      if user.failed_attempts >= max_attempts
        lockout_minutes = policy[:lockout_duration]
        user.update!(
          locked_at: Time.current,
          status: "suspended"
        )

        Management::AuditLogService.run!(
          action: "account_locked",
          actor: user,
          metadata: {
            reason: "Too many failed login attempts",
            failed_attempts: user.failed_attempts,
            max_attempts: max_attempts,
            lockout_duration: lockout_minutes
          }
        )
      end
    end

    def self.reset_failed_attempts!(user)
      user.update!(failed_attempts: 0, locked_at: nil)
    end

    def self.locked?(user)
      return false unless user.locked_at.present?
      return false if user.failed_attempts.nil? || user.failed_attempts == 0

      policy = PasswordPolicyService.active_policy(user.cooperative)
      lockout_minutes = policy[:lockout_duration]

      if user.locked_at < lockout_minutes.minutes.ago
        user.update!(failed_attempts: 0, locked_at: nil)
        return false
      end

      true
    end

    def self.remaining_lockout_time(user)
      return 0 unless user.locked_at.present?

      policy = PasswordPolicyService.active_policy(user.cooperative)
      lockout_minutes = policy[:lockout_duration]

      elapsed = Time.current - user.locked_at
      remaining = (lockout_minutes * 60) - elapsed.to_i
      [ remaining, 0 ].max
    end
  end
end
