class AddBranchIdToMembers < ActiveRecord::Migration[8.0]
  def change
    add_reference :members, :branch, foreign_key: { to_table: :management_branches }, null: true
  end
end
