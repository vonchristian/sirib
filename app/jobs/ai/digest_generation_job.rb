module Ai
  class DigestGenerationJob < ApplicationJob
    queue_as :default

    def perform(branch_id: nil, agent_id: nil)
      branches = if branch_id
        Management::Branch.where(id: branch_id)
      else
        Management::Branch.active
      end

      agent = if agent_id
        Ai::Agent.find(agent_id)
      else
        Ai::Agent.enabled.by_name.first
      end

      return unless agent&.enabled

      branches.find_each do |branch|
        Ai::BranchManagerService.call(branch: branch, agent: agent, save: true)
      end
    end
  end
end
