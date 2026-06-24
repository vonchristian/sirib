class AddAuthEnhancementsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :failed_attempts, :integer
    add_column :users, :locked_at, :datetime
    add_column :users, :password_changed_at, :datetime
    add_column :users, :force_password_change, :boolean
    add_column :users, :last_login_ip, :string
    add_column :users, :last_seen_at, :datetime
    add_column :users, :last_device, :string
    add_column :users, :session_version, :integer
  end
end
