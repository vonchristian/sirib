class AddMfaVerifiedAtToSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :sessions, :mfa_verified_at, :datetime
  end
end
