class CreateTreasurySavingsAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :treasury_savings_accounts do |t|
      t.references :savings_product, null: false, foreign_key: { to_table: :treasury_savings_products }
      t.string :depositor_type, null: false
      t.bigint :depositor_id, null: false
      t.integer :account_type, null: false, default: 0
      t.decimal :balance_cents, precision: 15, scale: 2, default: 0.0, null: false
      t.string :balance_currency, default: "PHP", null: false
      t.string :status, default: "active", null: false
      t.string :account_number, null: false
      t.datetime :opened_at
      t.datetime :closed_at
      t.timestamps
    end
    add_index :treasury_savings_accounts, [:depositor_type, :depositor_id], name: "idx_savings_accounts_on_depositor"
    add_index :treasury_savings_accounts, :account_number, unique: true
  end
end
