module Management
  class Permission < ApplicationRecord
    self.table_name = "management_permissions"

    has_many :role_permissions, class_name: "Management::RolePermission", dependent: :destroy
    has_many :roles, through: :role_permissions, class_name: "Management::Role"

    validates :action, :subject, presence: true
    validates :action, uniqueness: { scope: :subject }
  end
end
