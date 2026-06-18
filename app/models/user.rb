class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :cash_accounts, class_name: "Accounting::CashAccount", dependent: :destroy
  has_many :cash_sessions, class_name: "Treasury::CashSession", dependent: :destroy
  has_many :role_assignments, class_name: "Management::RoleAssignment", dependent: :destroy
  has_many :management_roles, through: :role_assignments, source: :role, class_name: "Management::Role"
  has_many :managed_branches, through: :role_assignments, source: :branch, class_name: "Management::Branch"

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

  def has_permission?(action, subject, branch: nil)
    role_assignments.active
      .then { |ra| branch ? ra.where(branch: branch) : ra }
      .joins(role: { role_permissions: :permission })
      .where(management_permissions: { action: action, subject: subject })
      .exists?
  end

  def management_role?(role_code)
    role_assignments.active.joins(:role).exists?(management_roles: { code: role_code })
  end
end
