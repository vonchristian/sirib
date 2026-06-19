class CreatePortalEnrollmentTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :portal_enrollment_tokens do |t|
      t.references :member, null: false, foreign_key: { to_table: :members }
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at

      t.timestamps
    end
    add_index :portal_enrollment_tokens, :token, unique: true
  end
end
