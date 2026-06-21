module Management
  class RolePermission < ApplicationRecord
    self.table_name = "management_role_permissions"
    include CooperativeScoped

    belongs_to :role, class_name: "Management::Role"
    belongs_to :permission, class_name: "Management::Permission"

    validates :role_id, uniqueness: { scope: :permission_id }
  end
end
