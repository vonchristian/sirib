module Management
  class Role < ApplicationRecord
    self.table_name = "management_roles"

    has_many :role_permissions, class_name: "Management::RolePermission", dependent: :destroy
    has_many :permissions, through: :role_permissions, class_name: "Management::Permission"
    has_many :role_assignments, class_name: "Management::RoleAssignment", dependent: :restrict_with_error
    has_many :workflow_steps, class_name: "Management::ApprovalWorkflowStep", foreign_key: :approver_role_id

    validates :name, :code, presence: true
    validates :code, uniqueness: true

    scope :by_rank, -> { order(rank: :asc) }
  end
end
