class CreateAiAgents < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_agents do |t|
      t.references :cooperative, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.boolean :enabled, default: true, null: false
      t.string :schedule, default: "daily", null: false
      t.timestamps
    end

    add_index :ai_agents, [ :cooperative_id, :name ], unique: true
  end
end
