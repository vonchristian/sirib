class CreateReconciliationResults < ActiveRecord::Migration[8.0]
  def change
    create_table :reconciliation_results do |t|
      t.string :check_name, null: false
      t.string :status, null: false
      t.integer :total_checked, default: 0
      t.integer :failures_count, default: 0
      t.jsonb :failures, default: []
      t.text :error_message
      t.references :cooperative, null: false, foreign_key: true
      t.datetime :checked_at, null: false
      t.timestamps
    end

    add_index :reconciliation_results, :checked_at
    add_index :reconciliation_results, [ :check_name, :checked_at ]
  end
end
