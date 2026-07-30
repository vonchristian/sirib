module Security
  class CleanupJob < ApplicationJob
    queue_as :default

    def perform
      cleanup_expired_sessions
      cleanup_old_password_histories
    end

    private

    def cleanup_expired_sessions
      Session.expired.where(revoked_at: nil).update_all(revoked_at: Time.current)
      Rails.logger.info "[SECURITY] Expired sessions cleaned up"
    end

    def cleanup_old_password_histories
      Security::PasswordHistory.where("created_at < ?", 1.year.ago).delete_all
    end
  end
end
