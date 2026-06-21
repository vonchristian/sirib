module Management
  class ApprovalWorkflowStep < ApplicationRecord
    self.table_name = "management_approval_workflow_steps"
    include CooperativeScoped

    belongs_to :approval_workflow, class_name: "Management::ApprovalWorkflow", touch: true
    belongs_to :approver_role, class_name: "Management::Role", optional: true
    belongs_to :approver_user, class_name: "User", optional: true

    has_many :approvals, class_name: "Management::Approval", foreign_key: :step_id

    validates :sequence, presence: true
    validates :sequence, uniqueness: { scope: :approval_workflow_id }
  end
end
