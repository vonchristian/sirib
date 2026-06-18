module Management
  class SystemHealthSnapshot < ApplicationRecord
    self.table_name = "management_system_health_snapshots"

    validates :metric_name, :captured_at, presence: true

    enum :status, { healthy: "healthy", warning: "warning", critical: "critical" }
  end
end
