class CreateEntryTemplateSystem < ActiveRecord::Migration[8.0]
  def change
    create_table :entry_templates do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :is_active, null: false, default: true
      t.jsonb :metadata, default: {}
      t.timestamps
    end
    add_index :entry_templates, :is_active

    create_table :entry_template_lines do |t|
      t.references :entry_template, null: false, foreign_key: true
      t.bigint :account_id, null: false
      t.string :direction, null: false
      t.string :amount_mode, null: false, default: "variable"
      t.decimal :fixed_amount, precision: 20, scale: 4
      t.integer :sequence_index, null: false, default: 0
      t.timestamps
    end
    add_index :entry_template_lines, :account_id
    add_foreign_key :entry_template_lines, :accounts

    add_column :entries, :source_type, :string
    add_column :entries, :source_id, :bigint
    add_column :entries, :total_amount_cents, :decimal, precision: 20, scale: 4
    add_index :entries, [:source_type, :source_id]
  end
end
