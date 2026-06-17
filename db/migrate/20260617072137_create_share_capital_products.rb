class CreateShareCapitalProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :share_capital_products do |t|
      t.string :product_code, null: false
      t.string :name, null: false
      t.text :description
      t.integer :share_type, null: false, default: 0
      t.string :status, null: false, default: "active"
      t.date :effective_date
      t.integer :price_per_share_cents, null: false, default: 0
      t.integer :minimum_required_shares, null: false, default: 1
      t.integer :maximum_allowed_shares
      t.integer :minimum_initial_purchase, null: false, default: 1
      t.boolean :allow_fractional_shares, null: false, default: false
      t.boolean :redeemable, null: false, default: true
      t.boolean :dividend_eligible, null: false, default: true
      t.boolean :voting_rights, null: false, default: true
      t.references :equity_ledger, null: true, foreign_key: { to_table: :ledgers }
      t.timestamps
    end

    add_index :share_capital_products, :product_code, unique: true
  end
end
