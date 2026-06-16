class CreateTreasurySavingsTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :treasury_savings_transactions do |t|
      t.references :savings_account, null: false, foreign_key: { to_table: :treasury_savings_accounts }
      t.integer :transaction_type, null: false
      t.decimal :amount_cents, precision: 15, scale: 2, null: false
      t.string :amount_currency, default: "PHP", null: false
      t.decimal :balance_before_cents, precision: 15, scale: 2, null: false
      t.decimal :balance_after_cents, precision: 15, scale: 2, null: false
      t.bigint :cash_account_id, null: false
      t.bigint :entry_id
      t.string :reference_number, null: false
      t.text :notes
      t.string :status, default: "completed", null: false
      t.datetime :posted_at, null: false
      t.timestamps
    end
    add_index :treasury_savings_transactions, :reference_number, unique: true
    add_index :treasury_savings_transactions, :entry_id
    add_index :treasury_savings_transactions, :cash_account_id
  end
end
