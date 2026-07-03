module Ai
  class AgentRun < ApplicationRecord
    self.table_name = "ai_agent_runs"
    include CooperativeScoped

    belongs_to :agent, class_name: "Ai::Agent"
    belongs_to :branch, class_name: "Management::Branch", optional: true

    has_many :observations, class_name: "Ai::Observation", foreign_key: :agent_run_id, dependent: :nullify
    has_many :recommendations, class_name: "Ai::Recommendation", foreign_key: :agent_run_id, dependent: :nullify
    has_many :digests, class_name: "Ai::Digest", foreign_key: :agent_run_id, dependent: :nullify

    validates :started_at, presence: true
    validates :status, inclusion: { in: %w[running completed failed] }

    enum :status, { running: "running", completed: "completed", failed: "failed" }

    scope :recent, -> { order(started_at: :desc) }

    def duration_ms
      return nil unless completed_at && started_at
      ((completed_at - started_at) * 1000).to_i
    end
  end
end
