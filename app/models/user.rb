class User < ApplicationRecord
  IDENTITY_STATUSES = %w[active suspended terminated].freeze

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :cash_accounts, class_name: "Accounting::CashAccount", dependent: :destroy
  has_many :cash_sessions, class_name: "Treasury::CashSession", dependent: :destroy
  has_many :role_assignments, class_name: "Management::RoleAssignment", dependent: :destroy
  has_many :management_roles, through: :role_assignments, source: :role, class_name: "Management::Role"
  has_many :managed_branches, through: :role_assignments, source: :branch, class_name: "Management::Branch"
  has_many :backup_codes, class_name: "Access::BackupCode", dependent: :destroy
  has_many :trusted_devices, class_name: "Access::TrustedDevice", dependent: :destroy
  has_many :mfa_attempt_logs, class_name: "Access::MfaAttemptLog", dependent: :destroy

  encrypts :otp_secret

  enum :role, {
    manager: 0,
    treasurer: 1,
    accountant: 2,
    loan_officer: 3
  }

  enum :status, {
    active: "active",
    suspended: "suspended",
    terminated: "terminated"
  }, prefix: true

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
  validates :employee_id, presence: true, uniqueness: { case_sensitive: false }, allow_nil: true
  validates :status, inclusion: { in: IDENTITY_STATUSES }, allow_nil: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  scope :active, -> { where(status: "active") }
  scope :suspended, -> { where(status: "suspended") }
  scope :terminated, -> { where(status: "terminated") }

  before_create :assign_employee_id
  before_create :set_default_status
  after_update :revoke_sessions_if_suspended, if: -> { saved_change_to_status? && status == "suspended" }

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

  def active?
    status == "active"
  end

  def suspended?
    status == "suspended"
  end

  def terminated?
    status == "terminated"
  end

  def status_active?
    active?
  end

  def permission_overrides_for(action, subject)
    return nil unless permission_overrides.present?

    permission_overrides.dig(subject.to_s, action.to_s)
  end

  private

  def assign_employee_id
    return if employee_id.present?

    loop do
      self.employee_id = SecureRandom.hex(4).upcase
      break unless self.class.exists?(employee_id: employee_id)
    end
  end

  def set_default_status
    self.status ||= "active"
  end

  def revoke_sessions_if_suspended
    sessions.where(revoked_at: nil).update_all(revoked_at: Time.current)
  end
end
