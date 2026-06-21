class Portal::EnrollmentToken < ApplicationRecord
  include CooperativeScoped

  TOKEN_LIFETIME = 48.hours

  belongs_to :member, class_name: "Membership::Member"

  scope :unused, -> { where(used_at: nil) }
  scope :valid, -> { unused.where(expires_at: Time.current..) }

  before_create :assign_token, :set_expiry

  def used?
    used_at.present?
  end

  def expired?
    expires_at < Time.current
  end

  def use!
    update!(used_at: Time.current)
  end

  private

  def assign_token
    self.token = generate_token
  end

  def set_expiry
    self.expires_at ||= TOKEN_LIFETIME.from_now
  end

  def generate_token
    loop do
      token = SecureRandom.urlsafe_base64(32)
      break token unless self.class.exists?(token: token)
    end
  end
end
