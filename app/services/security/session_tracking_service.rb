module Security
  class SessionTrackingService
    MAX_CONCURRENT_SESSIONS = 5

    def self.record_login!(user:, ip_address:, user_agent:)
      user.update!(
        last_login_ip: ip_address,
        last_seen_at: Time.current,
        last_device: user_agent&.truncate(255)
      )
    end

    def self.enforce_concurrent_limit(user)
      active_sessions = user.sessions.where(revoked_at: nil).order(created_at: :desc)
      return if active_sessions.count <= MAX_CONCURRENT_SESSIONS

      excess = active_sessions.offset(MAX_CONCURRENT_SESSIONS)
      excess.update_all(revoked_at: Time.current)
    end

    def self.invalidate_all_sessions(user)
      user.sessions.where(revoked_at: nil).update_all(revoked_at: Time.current)
    end

    def self.bump_session_version(user)
      user.increment!(:session_version)
      invalidate_all_sessions(user)
    end
  end
end
