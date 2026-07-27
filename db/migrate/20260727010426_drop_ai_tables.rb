class DropAiTables < ActiveRecord::Migration[8.0]
  def up
    drop_table :ai_recommendations
    drop_table :ai_digests
    drop_table :ai_observations
    drop_table :ai_agent_runs
    drop_table :ai_agents
  end

  def down
    create_table :ai_agents do |t|
      t.references :cooperative, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.boolean :enabled, default: false
      t.string :schedule
      t.timestamps
      t.index [ :cooperative_id, :name ], unique: true
    end

    create_table :ai_agent_runs do |t|
      t.references :agent, null: false, foreign_key: { to_table: :ai_agents }
      t.references :cooperative, null: false, foreign_key: true
      t.references :branch, foreign_key: { to_table: :management_branches }
      t.datetime :started_at
      t.datetime :completed_at
      t.string :status
      t.integer :tokens_used
      t.integer :execution_time_ms
      t.jsonb :result
      t.text :error_message
      t.timestamps
      t.index [ :agent_id, :started_at ]
      t.index :status
    end

    create_table :ai_observations do |t|
      t.references :cooperative, null: false, foreign_key: true
      t.references :branch, foreign_key: { to_table: :management_branches }
      t.references :agent_run, foreign_key: { to_table: :ai_agent_runs }
      t.string :category
      t.string :severity
      t.string :title, null: false
      t.text :summary
      t.jsonb :metadata
      t.datetime :detected_at
      t.datetime :resolved_at
      t.timestamps
      t.index :category
      t.index :severity
      t.index [ :branch_id, :detected_at ]
      t.index [ :branch_id, :resolved_at ]
    end

    create_table :ai_recommendations do |t|
      t.references :cooperative, null: false, foreign_key: true
      t.references :branch, foreign_key: { to_table: :management_branches }
      t.references :observation, foreign_key: { to_table: :ai_observations }
      t.references :agent_run, foreign_key: { to_table: :ai_agent_runs }
      t.string :priority
      t.string :title, null: false
      t.text :summary
      t.text :action_text
      t.decimal :confidence_score
      t.string :status
      t.datetime :dismissed_at
      t.datetime :completed_at
      t.datetime :acknowledged_at
      t.references :acknowledged_by, foreign_key: { to_table: :users }
      t.timestamps
      t.index :priority
      t.index :status
      t.index [ :branch_id, :status ]
    end

    create_table :ai_digests do |t|
      t.references :cooperative, null: false, foreign_key: true
      t.references :branch, foreign_key: { to_table: :management_branches }
      t.references :agent_run, foreign_key: { to_table: :ai_agent_runs }
      t.datetime :generated_at
      t.text :summary
      t.text :risk_summary
      t.text :recommendations_summary
      t.jsonb :metrics
      t.integer :observation_count
      t.integer :recommendation_count
      t.timestamps
      t.index [ :branch_id, :generated_at ]
    end
  end
end
