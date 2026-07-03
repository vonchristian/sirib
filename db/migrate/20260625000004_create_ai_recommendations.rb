class CreateAiRecommendations < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_recommendations do |t|
      t.references :cooperative, null: false, foreign_key: true
      t.references :branch, null: false, foreign_key: { to_table: :management_branches }
      t.references :observation, null: true, foreign_key: { to_table: :ai_observations }
      t.references :agent_run, null: true, foreign_key: { to_table: :ai_agent_runs }
      t.string :priority, default: "medium", null: false
      t.string :title, null: false
      t.text :summary
      t.text :action_text
      t.decimal :confidence_score, default: 0.0
      t.string :status, default: "open", null: false
      t.datetime :dismissed_at
      t.datetime :completed_at
      t.datetime :acknowledged_at
      t.bigint :acknowledged_by_id
      t.timestamps
    end

    add_index :ai_recommendations, :priority
    add_index :ai_recommendations, :status
    add_index :ai_recommendations, [ :branch_id, :status ]
  end
end
