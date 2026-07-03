module Ai
  class Observation < ApplicationRecord
    self.table_name = "ai_observations"
    include CooperativeScoped

    belongs_to :branch, class_name: "Management::Branch"
    belongs_to :agent_run, class_name: "Ai::AgentRun", optional: true

    has_many :recommendations, class_name: "Ai::Recommendation", foreign_key: :observation_id, dependent: :nullify

    validates :category, presence: true
    validates :severity, inclusion: { in: %w[critical high medium low] }
    validates :title, presence: true
    validates :detected_at, presence: true

    enum :severity, { critical: "critical", high: "high", medium: "medium", low: "low" }

    scope :unresolved, -> { where(resolved_at: nil) }
    scope :resolved, -> { where.not(resolved_at: nil) }
    scope :by_severity, -> { order(Arel.sql("CASE severity WHEN 'critical' THEN 0 WHEN 'high' THEN 1 WHEN 'medium' THEN 2 WHEN 'low' THEN 3 END")) }
    scope :recent, -> { order(detected_at: :desc) }
    scope :since, ->(time) { where(detected_at: time..) }

    def resolved?
      resolved_at.present?
    end

    def resolve!
      update!(resolved_at: Time.current)
    end
  end
end
