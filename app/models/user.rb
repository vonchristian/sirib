class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :cash_accounts, class_name: "Accounting::CashAccount", dependent: :destroy
  has_many :cash_sessions, class_name: "Treasury::CashSession", dependent: :destroy

  enum :role, {
    manager: 0,
    treasurer: 1,
    accountant: 2,
    loan_officer: 3
  }

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def current_cash_session
    return nil unless cash_accounts.any?
    Treasury::CashSession.for_today(self)
  end
end
