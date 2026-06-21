module Management
  class AuditLog < ApplicationRecord
    self.table_name = "management_audit_logs"
    include CooperativeScoped

    belongs_to :actor, class_name: "User", optional: true
    belongs_to :branch, class_name: "Management::Branch", optional: true
    belongs_to :auditable, polymorphic: true, optional: true

    scope :by_recent, -> { order(created_at: :desc) }
    scope :by_action, ->(action) { where(action: action) }
    scope :by_actor, ->(actor_id) { where(actor_id: actor_id) }

    def readonly?
      !new_record?
    end
  end
end
