class DropOtpColumnsFromMembers < ActiveRecord::Migration[8.0]
  def change
    remove_column :members, :otp_secret, :string
    remove_column :members, :otp_enabled, :boolean
    remove_column :members, :otp_verified_at, :timestamptz
  end
end
