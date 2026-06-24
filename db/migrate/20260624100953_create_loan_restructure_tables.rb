class CreateLoanRestructureTables < ActiveRecord::Migration[8.0]
  def change
    add_column :loans, :restructures_count, :integer, default: 0, null: false
    add_column :loans, :max_restructures, :integer, default: 2, null: false

    create_table :loan_schedules do |t|
      t.references :loan, null: false, foreign_key: true
      t.integer :version, null: false, default: 1
      t.string :status, null: false, default: "active"
      t.jsonb :schedule_data, default: [], null: false
      t.datetime :superseded_at
      t.timestamps
    end

    add_index :loan_schedules, [:loan_id, :version], unique: true
    add_index :loan_schedules, [:loan_id, :status]

    create_table :loan_links do |t|
      t.references :from_loan, null: false, foreign_key: { to_table: :loans }
      t.references :to_loan, null: false, foreign_key: { to_table: :loans }
      t.string :link_type, null: false
      t.decimal :amount_cents, precision: 20, scale: 2, default: 0.0, null: false
      t.string :amount_currency, default: "PHP", null: false
      t.text :reason
      t.timestamps
    end

    add_index :loan_links, [:from_loan_id, :link_type]
    add_index :loan_links, [:to_loan_id, :link_type]
    add_index :loan_links, [:from_loan_id, :to_loan_id], unique: true

    create_table :loan_events do |t|
      t.references :loan, null: false, foreign_key: true
      t.references :actor, polymorphic: true, null: false
      t.string :event_type, null: false
      t.string :status, null: false, default: "completed"
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

    add_index :loan_events, [:loan_id, :event_type]
    add_index :loan_events, [:loan_id, :created_at]

    create_table :loan_restructure_cases do |t|
      t.references :loan, null: false, foreign_key: true
      t.references :new_loan, foreign_key: { to_table: :loans }
      t.string :restructure_type, null: false
      t.string :status, null: false, default: "draft"
      t.jsonb :proposed_changes, default: {}, null: false
      t.jsonb :simulation_data, default: {}
      t.decimal :arrears_cents, precision: 20, scale: 2, default: 0.0, null: false
      t.string :arrears_currency, default: "PHP", null: false
      t.text :notes
      t.references :requested_by, foreign_key: { to_table: :users }
      t.references :approved_by, foreign_key: { to_table: :users }
      t.datetime :submitted_at
      t.datetime :reviewed_at
      t.datetime :executed_at
      t.timestamps
    end

    add_index :loan_restructure_cases, [:loan_id, :status]
    add_index :loan_restructure_cases, [:loan_id, :restructure_type]
  end
end
