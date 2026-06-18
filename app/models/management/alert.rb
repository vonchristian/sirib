module Management
  class Alert < ApplicationRecord
    self.table_name = "management_alerts"

    belongs_to :triggered_by, polymorphic: true, optional: true
    belongs_to :resolved_by, class_name: "User", optional: true

    validates :alert_type, :title, :severity, :status, presence: true

    enum :severity, { info: "info", warning: "warning", critical: "critical" }
    enum :status, { active: "active", resolved: "resolved" }

    scope :active, -> { where(status: :active) }
    scope :by_severity, -> { order(severity: :desc) }
    scope :by_type, -> { order(alert_type: :asc) }

    def resolve!(user)
      update!(resolved_by: user, resolved_at: Time.current, status: :resolved)
    end
  end
end
