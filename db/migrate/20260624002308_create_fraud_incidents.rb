class CreateFraudIncidents < ActiveRecord::Migration[8.0]
  def change
    create_table :fraud_incidents do |t|
      t.references :rule, null: false, foreign_key: { to_table: :fraud_rules }
      t.string :incident_type
      t.string :severity
      t.text :description
      t.jsonb :metadata
      t.references :actor, polymorphic: true, null: false
      t.datetime :resolved_at
      t.references :resolved_by, polymorphic: true
      t.string :resolution
      t.references :cooperative, null: false, foreign_key: true

      t.timestamps
    end
  end
end
