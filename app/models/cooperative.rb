class Cooperative < ApplicationRecord
  TENANT_STATUSES = %w[active inactive suspended provisioning failed].freeze

  has_many :membership_applications, class_name: "Membership::Application", dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :branches, class_name: "Management::Branch", dependent: :destroy
  belongs_to :vault_account, class_name: "Accounting::Account", optional: true

  validates :name, presence: true
  validates :schema_name, presence: true, uniqueness: true, format: { with: /\A[a-z][a-z0-9_]*\z/ }
  validates :subdomain, presence: true, uniqueness: { case_sensitive: false }, format: { with: /\A[a-z][a-z0-9-]*\z/ }
  validates :status, inclusion: { in: TENANT_STATUSES }

  enum :status, {
    active: "active",
    inactive: "inactive",
    suspended: "suspended",
    provisioning: "provisioning",
    failed: "failed"
  }, prefix: true

  scope :active, -> { where(status: "active") }
  scope :provisioned, -> { where.not(provisioned_at: nil) }

  before_validation :set_schema_name, on: :create
  before_validation :set_subdomain, on: :create

  def provision!
    return false unless may_provision?

    update!(status: :provisioning)
    Tenant::ProvisioningService.call(self)
    true
  end

  def deactivate!
    update!(status: "inactive")
  end

  def activate!
    update!(status: "active")
  end

  def provisioned?
    provisioned_at.present?
  end

  def tenant_schema
    schema_name
  end

  def to_param
    subdomain
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[name subdomain status created_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[users branches]
  end

  private

  def set_schema_name
    return if schema_name.present?

    base = name.parameterize.underscore.gsub("-", "_") if name.present?
    return unless base

    self.schema_name = loop do
      candidate = "tenant_#{base}"
      break candidate unless self.class.exists?(schema_name: candidate)
      base = "#{base}_#{SecureRandom.hex(2)}"
    end
  end

  def set_subdomain
    return if subdomain.present?

    base = name.parameterize.dasherize.gsub("_", "-") if name.present?
    return unless base

    self.subdomain = loop do
      break base unless self.class.exists?(subdomain: base)
      base = "#{base}-#{SecureRandom.hex(2)}"
    end
  end

  def may_provision?
    status_inactive? || status_failed?
  end
end
