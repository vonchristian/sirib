class CreateAiAgentRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_agent_runs do |t|
      t.references :cooperative, null: false, foreign_key: true
      t.references :agent, null: false, foreign_key: { to_table: :ai_agents }
      t.references :branch, null: true, foreign_key: { to_table: :management_branches }
      t.datetime :started_at, null: false
      t.datetime :completed_at
      t.string :status, default: "running", null: false
      t.integer :tokens_used, default: 0
      t.integer :execution_time_ms, default: 0
      t.jsonb :result, default: {}
      t.text :error_message
      t.timestamps
    end

    add_index :ai_agent_runs, :status
    add_index :ai_agent_runs, [ :agent_id, :started_at ]
  end
end
