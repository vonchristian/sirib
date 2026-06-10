class User < ApplicationRecord
  has_secure_password
  belongs_to :role
  has_many :sessions, dependent: :destroy
  has_many :cash_accounts, class_name: "Accounting::CashAccount", dependent: :destroy

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  delegate(*Role.predicate_methods, to: :role, allow_nil: true)
end
