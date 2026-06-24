module AutoAudit
  extend ActiveSupport::Concern

  AUDITED_ACTIONS = %w[create update destroy].freeze

  included do
    after_create :audit_create, if: :auditable?
    after_update :audit_update, if: :auditable?
    after_destroy :audit_destroy, if: :auditable?
  end

  private

  def auditable?
    return false if Current.user.nil?
    return false if respond_to?(:skip_audit?) && skip_audit?

    true
  end

  def audit_create
    record_audit("create", {}, to_audit_hash)
  end

  def audit_update
    return unless saved_changes.any?

    record_audit("update", saved_changes_before_cast, to_audit_hash)
  end

  def audit_destroy
    record_audit("destroy", to_audit_hash, {})
  end

  def record_audit(action, before_state, after_state)
    Management::AuditLogService.run!(
      action: action,
      auditable: self,
      actor: Current.user,
      changes: { before: before_state, after: after_state }
    )
  rescue => e
    Rails.logger.warn "Audit failed for #{self.class} ##{id}: #{e.message}"
  end

  def to_audit_hash
    respond_to?(:audit_attributes) ? audit_attributes : attributes
  end
end
