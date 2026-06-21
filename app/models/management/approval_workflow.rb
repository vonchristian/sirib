module Management
  class ApprovalWorkflow < ApplicationRecord
    self.table_name = "management_approval_workflows"
    include CooperativeScoped

    has_many :steps, -> { order(sequence: :asc) }, class_name: "Management::ApprovalWorkflowStep", dependent: :destroy
    has_many :approval_requests, class_name: "Management::ApprovalRequest", foreign_key: :workflow_id

    validates :name, presence: true

    accepts_nested_attributes_for :steps, allow_destroy: true
  end
end
