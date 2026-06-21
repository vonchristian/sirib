class Portal::Session < ApplicationRecord
  include CooperativeScoped

  STEP_UP_DURATION = 15.minutes

  belongs_to :member, class_name: "Membership::Member"

  scope :active, -> { where(revoked_at: nil) }

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
