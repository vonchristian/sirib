module Security
  class PasswordHistoryService
    def self.record_password_change!(user)
      Security::PasswordHistory.create!(
        user: user,
        password_digest: user.password_digest
      )
    end

    def self.password_expired?(user)
      return false unless user.password_changed_at

      policy = PasswordPolicyService.active_policy(user.cooperative)
      expiry_days = policy[:password_expiry_days]

      user.password_changed_at < expiry_days.days.ago
    end

    def self.needs_password_change?(user)
      return true if user.force_password_change?
      return true if user.password_changed_at.nil?

      password_expired?(user)
    end

    def self.password_in_history?(user, raw_password)
      policy = PasswordPolicyService.active_policy(user.cooperative)
      history_count = policy[:password_history_count]
      return false if history_count == 0

      recent = Security::PasswordHistory.where(user: user)
        .order(created_at: :desc)
        .limit(history_count)

      recent.any? do |entry|
        BCrypt::Password.new(entry.password_digest) == raw_password
      rescue BCrypt::Errors::InvalidHash
        false
      end
    end
  end
end
