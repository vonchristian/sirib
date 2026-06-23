class AddStatusAndPostableToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :status, :string
    add_index :accounts, :status
    add_column :accounts, :postable, :boolean
    add_index :accounts, :postable
    add_column :accounts, :created_by_id, :uuid
    add_column :accounts, :modified_by_id, :uuid
  end
end
