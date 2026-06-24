module Security
  class CleanupJob < ApplicationJob
    queue_as :default

    def perform
      cleanup_expired_sessions
      cleanup_stale_mfa_attempts
      cleanup_old_password_histories
      cleanup_expired_trusted_devices
    end

    private

    def cleanup_expired_sessions
      Session.expired.where(revoked_at: nil).update_all(revoked_at: Time.current)
      Rails.logger.info "[SECURITY] Expired sessions cleaned up"
    end

    def cleanup_stale_mfa_attempts
      Access::MfaAttemptLog.where("created_at < ?", 90.days.ago).delete_all
    end

    def cleanup_old_password_histories
      Security::PasswordHistory.where("created_at < ?", 1.year.ago).delete_all
    end

    def cleanup_expired_trusted_devices
      Access::TrustedDevice.where("expires_at < ?", Time.current).delete_all
    end
  end
end
