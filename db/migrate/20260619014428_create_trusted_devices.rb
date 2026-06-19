class CreateTrustedDevices < ActiveRecord::Migration[8.0]
  def change
    create_table :trusted_devices do |t|
      t.references :user, null: false, foreign_key: true
      t.string :device_fingerprint_hash, null: false
      t.datetime :last_used_at, null: false
      t.datetime :expires_at, null: false
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :trusted_devices, [:user_id, :device_fingerprint_hash], unique: true
    add_index :trusted_devices, :expires_at
  end
end
