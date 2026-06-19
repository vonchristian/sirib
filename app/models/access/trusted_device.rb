module Access
  class TrustedDevice < ApplicationRecord
    self.table_name = "trusted_devices"

    TRUST_DURATION = 30.days

    belongs_to :user

    validates :device_fingerprint_hash, presence: true
    validates :last_used_at, presence: true
    validates :expires_at, presence: true

    scope :active, -> { where(expires_at: Time.current..) }
    scope :expired, -> { where(expires_at: ...Time.current) }

    def active?
      expires_at > Time.current
    end

    def touch_usage!
      update!(last_used_at: Time.current, expires_at: TRUST_DURATION.from_now)
    end

    def self.trusted?(user, fingerprint_hash)
      active.exists?(user: user, device_fingerprint_hash: fingerprint_hash)
    end

    def self.trust!(user, fingerprint_hash, ip_address: nil, user_agent: nil)
      device = find_or_initialize_by(user: user, device_fingerprint_hash: fingerprint_hash)
      device.update!(
        last_used_at: Time.current,
        expires_at: TRUST_DURATION.from_now,
        ip_address: ip_address,
        user_agent: user_agent
      )
      device
    end

    def self.revoke_all_for(user)
      where(user: user).update_all(expires_at: Time.current)
    end

    def self.revoke_expired!
      expired.delete_all
    end
  end
end
