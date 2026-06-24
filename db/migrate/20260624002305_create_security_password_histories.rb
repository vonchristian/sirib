class CreateSecurityPasswordHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :security_password_histories do |t|
      t.references :user, null: false, foreign_key: true
      t.string :password_digest

      t.timestamps
    end
    add_index :security_password_histories, :created_at
  end
end
