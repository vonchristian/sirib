module Management
  class ApprovalRequest < ApplicationRecord
    self.table_name = "management_approval_requests"
    include CooperativeScoped

    belongs_to :requestable, polymorphic: true
    belongs_to :workflow, class_name: "Management::ApprovalWorkflow"
    belongs_to :requested_by, class_name: "User"

    has_many :approvals, class_name: "Management::Approval", foreign_key: :approval_request_id, dependent: :destroy

    validates :requested_by, presence: true

    enum :status, { pending: "pending", approved: "approved", rejected: "rejected", cancelled: "cancelled" }

    scope :pending, -> { where(status: :pending) }
    scope :approved, -> { where(status: :approved) }
    scope :rejected, -> { where(status: :rejected) }
  end
end
