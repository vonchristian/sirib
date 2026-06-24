class CreateSecurityPasswordPolicies < ActiveRecord::Migration[8.0]
  def change
    create_table :security_password_policies do |t|
      t.string :name
      t.integer :min_length
      t.boolean :require_uppercase
      t.boolean :require_lowercase
      t.boolean :require_digits
      t.boolean :require_symbols
      t.integer :max_failed_attempts
      t.integer :lockout_duration
      t.integer :password_expiry_days
      t.integer :password_history_count
      t.references :cooperative, null: false, foreign_key: true
      t.boolean :active

      t.timestamps
    end
  end
end
