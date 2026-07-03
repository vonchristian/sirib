class IdempotencyKey < ApplicationRecord
  include CooperativeScoped

  belongs_to :resource, polymorphic: true, optional: true

  validates :key, presence: true
  validates :service, presence: true
  validates :expires_at, presence: true
  validates :key, uniqueness: { scope: :cooperative_id }

  scope :expired, -> { where("expires_at < ?", Time.current) }
  scope :active, -> { where("expires_at >= ?", Time.current) }

  def expired?
    expires_at < Time.current
  end
end
