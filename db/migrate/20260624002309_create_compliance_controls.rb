class CreateComplianceControls < ActiveRecord::Migration[8.0]
  def change
    create_table :compliance_controls do |t|
      t.string :name
      t.text :description
      t.string :category
      t.string :frequency
      t.boolean :active
      t.jsonb :config
      t.references :cooperative, null: false, foreign_key: true

      t.timestamps
    end
  end
end
