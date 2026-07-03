class CreateAiDigests < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_digests do |t|
      t.references :cooperative, null: false, foreign_key: true
      t.references :branch, null: false, foreign_key: { to_table: :management_branches }
      t.references :agent_run, null: true, foreign_key: { to_table: :ai_agent_runs }
      t.datetime :generated_at, null: false
      t.text :summary
      t.text :risk_summary
      t.text :recommendations_summary
      t.jsonb :metrics, default: {}
      t.integer :observation_count, default: 0
      t.integer :recommendation_count, default: 0
      t.timestamps
    end

    add_index :ai_digests, [ :branch_id, :generated_at ]
  end
end
