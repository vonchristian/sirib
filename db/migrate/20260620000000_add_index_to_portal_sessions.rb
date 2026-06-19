class AddIndexToPortalSessions < ActiveRecord::Migration[8.0]
  def change
    add_index :portal_sessions, [:member_id, :revoked_at], name: "index_portal_sessions_member_id_revoked_at"
  end
end