class DropPortalStatusFromMembers < ActiveRecord::Migration[8.0]
  def change
    safety_assured { remove_column :members, :portal_status, :string }
  end
end
