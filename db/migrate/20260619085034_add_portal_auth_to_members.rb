class AddPortalAuthToMembers < ActiveRecord::Migration[8.0]
  def change
    add_column :members, :member_identifier, :string
    add_index :members, :member_identifier, unique: true
    add_column :members, :password_digest, :string
    add_column :members, :otp_secret, :string
    add_column :members, :otp_enabled, :boolean, default: false, null: false
    add_column :members, :otp_verified_at, :datetime
    add_column :members, :last_login_at, :datetime
    add_column :members, :portal_status, :string, default: "inactive", null: false
  end
end
