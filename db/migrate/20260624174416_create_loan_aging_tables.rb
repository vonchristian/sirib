class CreateLoanAgingTables < ActiveRecord::Migration[8.0]
  def change
    create_table :loan_aging_groups do |t|
      t.bigint :cooperative_id, null: false
      t.string :name, null: false
      t.integer :min_days, null: false, default: 0
      t.integer :max_days
      t.integer :display_order, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :loan_aging_groups, :cooperative_id
    add_index :loan_aging_groups, [ :cooperative_id, :display_order ]
    add_index :loan_aging_groups, [ :cooperative_id, :name ], unique: true

    create_table :loan_agings do |t|
      t.bigint :cooperative_id, null: false
      t.bigint :loan_id, null: false
      t.bigint :loan_aging_group_id, null: false
      t.integer :days_past_due, null: false, default: 0
      t.date :oldest_unpaid_due_date
      t.decimal :outstanding_principal_cents, null: false, default: 0
      t.decimal :outstanding_interest_cents, null: false, default: 0
      t.decimal :penalty_amount_cents, null: false, default: 0
      t.decimal :total_exposure_cents, null: false, default: 0
      t.datetime :calculated_at, null: false
      t.timestamps
    end
    add_index :loan_agings, :cooperative_id
    add_index :loan_agings, :loan_id, unique: true
    add_index :loan_agings, :loan_aging_group_id
    add_index :loan_agings, :days_past_due
    add_foreign_key :loan_agings, :loans
    add_foreign_key :loan_agings, :loan_aging_groups

    create_table :loan_aging_snapshots do |t|
      t.bigint :cooperative_id, null: false
      t.bigint :loan_aging_group_id, null: false
      t.date :snapshot_date, null: false
      t.integer :loan_count, null: false, default: 0
      t.integer :member_count, null: false, default: 0
      t.decimal :principal_amount_cents, null: false, default: 0
      t.decimal :interest_amount_cents, null: false, default: 0
      t.decimal :total_exposure_cents, null: false, default: 0
      t.timestamps
    end
    add_index :loan_aging_snapshots, :cooperative_id
    add_index :loan_aging_snapshots, [ :snapshot_date, :loan_aging_group_id ], unique: true
    add_index :loan_aging_snapshots, :snapshot_date
    add_foreign_key :loan_aging_snapshots, :loan_aging_groups
  end
end
