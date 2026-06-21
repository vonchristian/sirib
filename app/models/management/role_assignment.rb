module Management
  class RoleAssignment < ApplicationRecord
    self.table_name = "management_role_assignments"
    include CooperativeScoped

    belongs_to :user
    belongs_to :role, class_name: "Management::Role"
    belongs_to :branch, class_name: "Management::Branch", optional: true
    belongs_to :department, class_name: "Management::Department", optional: true

    scope :active, -> { where(arel_table[:active_from].lteq(Date.current)).where(arel_table[:active_until].eq(nil).or(arel_table[:active_until].gteq(Date.current))) }
  end
end
