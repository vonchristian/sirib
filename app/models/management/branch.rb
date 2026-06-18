module Management
  class Branch < ApplicationRecord
    self.table_name = "management_branches"

    belongs_to :cooperative, optional: true
    belongs_to :parent, class_name: "Management::Branch", optional: true

    has_many :departments, class_name: "Management::Department", dependent: :destroy
    has_many :children, class_name: "Management::Branch", foreign_key: :parent_id
    has_many :role_assignments, class_name: "Management::RoleAssignment"
    has_many :performance_snapshots, class_name: "Management::BranchPerformanceSnapshot"
    has_many :risk_indicators, class_name: "Management::RiskIndicator"

    validates :name, :code, presence: true
    validates :code, uniqueness: true

    enum :status, { active: "active", inactive: "inactive" }

    scope :active, -> { where(status: :active) }
    scope :by_name, -> { order(name: :asc) }

    def full_name
      parent ? "#{parent.name} > #{name}" : name
    end
  end
end
