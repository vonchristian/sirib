class CreateShareCapitalTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :share_capital_transactions do |t|
      t.references :share_capital_account, null: false, foreign_key: { to_table: :share_capital_accounts }
      t.integer :transaction_type, null: false, default: 0
      t.integer :shares, null: false
      t.integer :price_per_share_cents, null: false
      t.integer :total_amount_cents, null: false
      t.references :cash_account, null: true, foreign_key: { to_table: :accounts }
      t.references :entry, null: true, foreign_key: { to_table: :entries }
      t.string :reference_number, null: false
      t.string :status, null: false, default: "completed"
      t.datetime :posted_at, null: false
      t.integer :posted_by_id, null: false
      t.text :notes
      t.timestamps
    end

    add_index :share_capital_transactions, :reference_number, unique: true
  end
end
