class CreateAiObservations < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_observations do |t|
      t.references :cooperative, null: false, foreign_key: true
      t.references :branch, null: false, foreign_key: { to_table: :management_branches }
      t.references :agent_run, null: true, foreign_key: { to_table: :ai_agent_runs }
      t.string :category, null: false
      t.string :severity, default: "medium", null: false
      t.string :title, null: false
      t.text :summary
      t.jsonb :metadata, default: {}
      t.datetime :detected_at, null: false
      t.datetime :resolved_at
      t.timestamps
    end

    add_index :ai_observations, :severity
    add_index :ai_observations, :category
    add_index :ai_observations, [ :branch_id, :detected_at ]
    add_index :ai_observations, [ :branch_id, :resolved_at ]
  end
end
