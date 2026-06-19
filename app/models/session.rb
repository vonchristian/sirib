class Session < ApplicationRecord
  STEP_UP_DURATION = 15.minutes

  belongs_to :user

  scope :active, -> { where(revoked_at: nil) }
  scope :expired, -> { where(arel_table[:revoked_at].lt(Time.current)).or(where(arel_table[:last_activity_at].lt(Identity::ContextResolver::IDLE_TIMEOUT.ago))) }

  def active?
    revoked_at.nil?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def touch_activity!
    update!(last_activity_at: Time.current)
  end

  def mfa_verified?
    mfa_verified_at.present? && mfa_verified_at > STEP_UP_DURATION.ago
  end

  def verify_mfa!
    update!(mfa_verified_at: Time.current)
  end

  def expire_mfa_verification!
    update!(mfa_verified_at: nil)
  end
end
