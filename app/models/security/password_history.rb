class Security::PasswordHistory < ApplicationRecord
  self.table_name = "security_password_histories"

  belongs_to :user

  validates :password_digest, presence: true

  scope :recent, ->(limit = 5) { order(created_at: :desc).limit(limit) }
end
