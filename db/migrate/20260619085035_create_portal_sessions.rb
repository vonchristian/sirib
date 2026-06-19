class CreatePortalSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :portal_sessions do |t|
      t.references :member, null: false, foreign_key: { to_table: :members }
      t.string :ip_address
      t.text :user_agent
      t.datetime :revoked_at
      t.datetime :last_activity_at
      t.datetime :mfa_verified_at

      t.timestamps
    end
    add_index :portal_sessions, :revoked_at
    add_index :portal_sessions, :last_activity_at
  end
end
