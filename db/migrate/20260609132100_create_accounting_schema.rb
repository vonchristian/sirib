class CreateAccountingSchema < ActiveRecord::Migration[8.0]
  def up
    execute "CREATE TYPE account_type AS ENUM ('asset', 'equity', 'liability', 'revenue', 'expense')"

    create_table :ledgers do |t|
      t.string :name, null: false
      t.string :account_code, null: false
      t.boolean :contra, default: false
      t.column :account_type, :account_type, null: false
      t.timestamps
    end
    add_index :ledgers, :account_code, unique: true

    create_table :accounts do |t|
      t.references :ledger, null: false, foreign_key: true
      t.string :name, null: false
      t.string :account_code, null: false
      t.boolean :contra, default: false
      t.column :account_type, :account_type, null: false
      t.timestamps
    end
    add_index :accounts, :account_code, unique: true

    create_table :entries do |t|
      t.string :reference_number, null: false
      t.text :description, null: false
      t.datetime :posted_at, null: false
      t.timestamps
    end
    add_index :entries, :reference_number, unique: true
    add_index :entries, :posted_at

    create_table :amount_lines do |t|
      t.references :entry, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.integer :amount_type, null: false
      t.integer :amount_cents, null: false
      t.string :amount_currency, limit: 3, null: false, default: "PHP"
      t.timestamps
    end
    add_index :amount_lines, [:account_id, :entry_id]

    create_table :running_balances do |t|
      t.references :account, null: true, foreign_key: true
      t.references :ledger, null: false, foreign_key: true
      t.date :as_of_date, null: false
      t.integer :balance_cents, null: false
      t.string :balance_currency, limit: 3, null: false, default: "PHP"
      t.timestamps
    end
    add_index :running_balances, [:account_id, :as_of_date],
              unique: true,
              name: "idx_running_balances_on_account_date",
              where: "account_id IS NOT NULL"
    add_index :running_balances, [:ledger_id, :as_of_date],
              unique: true,
              name: "idx_running_balances_on_ledger_date",
              where: "account_id IS NULL"
  end

  def down
    drop_table :running_balances
    drop_table :amount_lines
    drop_table :entries
    drop_table :accounts
    drop_table :ledgers
    execute "DROP TYPE IF EXISTS account_type"
  end
end
