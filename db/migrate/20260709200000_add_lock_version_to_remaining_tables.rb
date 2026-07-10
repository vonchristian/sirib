class AddLockVersionToRemainingTables < ActiveRecord::Migration[8.0]
  def change
    add_column :loan_schedules, :lock_version, :integer, default: 0, null: false
    add_column :loan_events, :lock_version, :integer, default: 0, null: false
    add_column :members, :lock_version, :integer, default: 0, null: false
    add_column :management_approval_requests, :lock_version, :integer, default: 0, null: false
  end
end
