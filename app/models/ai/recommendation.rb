module Ai
  class Recommendation < ApplicationRecord
    self.table_name = "ai_recommendations"
    include CooperativeScoped

    belongs_to :branch, class_name: "Management::Branch"
    belongs_to :observation, class_name: "Ai::Observation", optional: true
    belongs_to :agent_run, class_name: "Ai::AgentRun", optional: true

    validates :priority, inclusion: { in: %w[critical high medium low] }
    validates :title, presence: true
    validates :status, inclusion: { in: %w[open acknowledged dismissed completed] }

    enum :priority, { critical: "critical", high: "high", medium: "medium", low: "low" }
    enum :status, { open: "open", acknowledged: "acknowledged", dismissed: "dismissed", completed: "completed" }

    scope :active, -> { where(status: %w[open acknowledged]) }
    scope :by_priority, -> { order(Arel.sql("CASE priority WHEN 'critical' THEN 0 WHEN 'high' THEN 1 WHEN 'medium' THEN 2 WHEN 'low' THEN 3 END")) }
    scope :recent, -> { order(created_at: :desc) }

    def active?
      %w[open acknowledged].include?(status)
    end

    def acknowledge!(user)
      update!(status: "acknowledged", acknowledged_at: Time.current, acknowledged_by_id: user.id)
    end

    def dismiss!
      update!(status: "dismissed", dismissed_at: Time.current)
    end

    def complete!
      update!(status: "completed", completed_at: Time.current)
    end
  end
end
