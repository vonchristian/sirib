class DropPortalStatusFromMembers < ActiveRecord::Migration[8.0]
  def change
    remove_column :members, :portal_status, :string
  end
end
