class AddIdentityToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :employee_id, :string
    add_index :users, :employee_id, unique: true
    add_column :users, :full_name, :string
    add_column :users, :status, :string
    add_column :users, :permission_overrides, :jsonb
  end
end
