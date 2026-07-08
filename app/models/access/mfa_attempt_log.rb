module Access
  class MfaAttemptLog < ApplicationRecord
    self.table_name = "mfa_attempt_logs"

    belongs_to :user

    validates :action, presence: true
    validates :success, inclusion: { in: [ true, false ] }

    scope :successful, -> { where(success: true) }
    scope :failed, -> { where(success: false) }
    scope :recent, -> { where(created_at: 10.minutes.ago..) }
    scope :by_action, ->(action) { where(action: action) }

    def self.rate_limited?(user, max_attempts: 5, within: 10.minutes)
      where(user: user, success: false)
        .where(created_at: within.ago..)
        .count >= max_attempts
    end

    def self.log(user, action:, success:, ip_address: nil, user_agent: nil, device_fingerprint: nil, failure_reason: nil, metadata: {})
      create!(
        user: user,
        action: action,
        success: success,
        ip_address: ip_address,
        user_agent: user_agent,
        device_fingerprint: device_fingerprint,
        failure_reason: failure_reason,
        metadata: metadata
      )
    end
  end
end
