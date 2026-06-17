class CreateShareCapitalAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :share_capital_accounts do |t|
      t.references :member, null: false, foreign_key: true
      t.references :share_product, null: false, foreign_key: { to_table: :share_capital_products }
      t.string :account_number, null: false
      t.string :status, null: false, default: "active"
      t.datetime :opened_at, null: false
      t.integer :opened_by_id, null: false
      t.string :branch
      t.text :remarks
      t.references :equity_account, null: true, foreign_key: { to_table: :accounts }
      t.integer :shares_owned, null: false, default: 0
      t.integer :paid_up_shares, null: false, default: 0
      t.timestamps
    end

    add_index :share_capital_accounts, :account_number, unique: true
    add_index :share_capital_accounts, [:member_id, :share_product_id], unique: true
  end
end
