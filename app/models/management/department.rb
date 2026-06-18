module Management
  class Department < ApplicationRecord
    self.table_name = "management_departments"

    belongs_to :branch, class_name: "Management::Branch"
    has_many :teams, class_name: "Management::Team", dependent: :destroy
    has_many :role_assignments, class_name: "Management::RoleAssignment"

    validates :name, :code, presence: true
    validates :code, uniqueness: { scope: :branch_id }

    scope :by_name, -> { order(name: :asc) }
  end
end
