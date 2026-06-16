class CreateTreasuryVouchers < ActiveRecord::Migration[8.0]
  def change
    create_table :treasury_vouchers do |t|
      t.string :type, null: false
      t.references :cash_session, null: false, foreign_key: { to_table: :treasury_cash_sessions }
      t.string :voucher_number, null: false
      t.string :status, null: false, default: "pending"
      t.decimal :amount_cents, precision: 15, scale: 2, null: false
      t.string :amount_currency, null: false, default: "PHP"
      t.text :description
      t.references :cash_account, null: false, foreign_key: { to_table: :accounts }
      t.references :entry, foreign_key: { to_table: :entries }
      t.datetime :posted_at
      t.string :counterparty_type
      t.bigint :counterparty_id
      t.string :category, null: false
      t.string :transactable_type
      t.bigint :transactable_id
      t.timestamps
    end

    add_index :treasury_vouchers, :voucher_number, unique: true
    add_index :treasury_vouchers, :status
    add_index :treasury_vouchers, [:counterparty_type, :counterparty_id], name: "idx_vouchers_on_counterparty"
    add_index :treasury_vouchers, [:transactable_type, :transactable_id], name: "idx_vouchers_on_transactable"
    add_index :treasury_vouchers, :type
  end
end
