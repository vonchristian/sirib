class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :cash_accounts, class_name: "Accounting::CashAccount", dependent: :destroy
  has_many :cash_account_records, through: :cash_accounts, source: :account

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
