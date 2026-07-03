module Ai
  class Agent < ApplicationRecord
    self.table_name = "ai_agents"
    include CooperativeScoped

    has_many :agent_runs, class_name: "Ai::AgentRun", foreign_key: :agent_id, dependent: :destroy

    validates :name, presence: true, uniqueness: { scope: :cooperative_id }
    validates :schedule, inclusion: { in: %w[daily hourly weekly] }

    scope :enabled, -> { where(enabled: true) }
    scope :by_name, -> { order(name: :asc) }
  end
end
