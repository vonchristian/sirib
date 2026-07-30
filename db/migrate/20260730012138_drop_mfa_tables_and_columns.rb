class DropMfaTablesAndColumns < ActiveRecord::Migration[8.0]
  def change
    drop_table :backup_codes
    drop_table :mfa_attempt_logs
    drop_table :trusted_devices

    remove_column :sessions, :mfa_verified_at, :timestamptz
    remove_column :users, :otp_secret, :string
    remove_column :users, :otp_enabled, :boolean
    remove_column :users, :otp_verified_at, :timestamptz
  end
end
