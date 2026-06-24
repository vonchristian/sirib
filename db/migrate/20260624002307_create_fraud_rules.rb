class CreateFraudRules < ActiveRecord::Migration[8.0]
  def change
    create_table :fraud_rules do |t|
      t.string :name
      t.text :description
      t.string :rule_type
      t.jsonb :config
      t.string :severity
      t.boolean :active
      t.references :cooperative, null: false, foreign_key: true

      t.timestamps
    end
  end
end
