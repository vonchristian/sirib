module Ai
  class Digest < ApplicationRecord
    self.table_name = "ai_digests"
    include CooperativeScoped

    belongs_to :branch, class_name: "Management::Branch"
    belongs_to :agent_run, class_name: "Ai::AgentRun", optional: true

    validates :generated_at, presence: true

    scope :recent, -> { order(generated_at: :desc) }
    scope :today, -> { where(generated_at: Date.current.all_day) }
  end
end
