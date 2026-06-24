class CreateComplianceEvidences < ActiveRecord::Migration[8.0]
  def change
    create_table :compliance_evidences do |t|
      t.references :control, null: false, foreign_key: { to_table: :compliance_controls }
      t.string :status
      t.string :evidence_type
      t.jsonb :metadata
      t.datetime :verified_at
      t.references :verified_by, polymorphic: true
      t.datetime :expires_at
      t.references :cooperative, null: false, foreign_key: true

      t.timestamps
    end
  end
end
