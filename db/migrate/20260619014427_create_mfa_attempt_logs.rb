class CreateMfaAttemptLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :mfa_attempt_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :action, null: false
      t.boolean :success, null: false
      t.string :ip_address
      t.text :user_agent
      t.string :device_fingerprint
      t.string :failure_reason
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :mfa_attempt_logs, :created_at
    add_index :mfa_attempt_logs, [:user_id, :created_at]
    add_index :mfa_attempt_logs, :action
  end
end
