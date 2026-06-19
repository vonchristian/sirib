class AddSessionSecurityToSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :sessions, :revoked_at, :datetime
    add_column :sessions, :last_activity_at, :datetime
  end
end
