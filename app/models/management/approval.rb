module Management
  class Approval < ApplicationRecord
    self.table_name = "management_approvals"

    belongs_to :approval_request, class_name: "Management::ApprovalRequest", touch: true
    belongs_to :step, class_name: "Management::ApprovalWorkflowStep"
    belongs_to :approver, class_name: "User"

    validates :status, :signed_at, presence: true

    enum :status, { approved: "approved", rejected: "rejected" }

    after_create :update_approval_request_status

    private

    def update_approval_request_status
      approval_request.update(status: status)
    end
  end
end
