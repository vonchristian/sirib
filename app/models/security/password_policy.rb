class Security::PasswordPolicy < ApplicationRecord
  self.table_name = "security_password_policies"

  include CooperativeScoped

  validates :name, presence: true, uniqueness: { scope: :cooperative_id }
  validates :min_length, numericality: { greater_than_or_equal_to: 6, less_than_or_equal_to: 128 }, allow_nil: true
  validates :max_failed_attempts, numericality: { greater_than: 0 }, allow_nil: true
  validates :lockout_duration, numericality: { greater_than: 0 }, allow_nil: true
  validates :password_expiry_days, numericality: { greater_than: 0 }, allow_nil: true
  validates :password_history_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }
end
