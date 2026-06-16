class CreateTreasuryTimeDeposits < ActiveRecord::Migration[8.0]
  def change
    create_table :treasury_time_deposits do |t|
      t.references :depositor, polymorphic: true, null: false
      t.references :time_deposit_product, null: false, foreign_key: { to_table: :treasury_time_deposit_products }
      t.integer :amount_cents, null: false, default: 0
      t.string :amount_currency, default: "PHP", null: false
      t.decimal :interest_rate, precision: 8, scale: 4, null: false
      t.date :matured_on
      t.integer :interest_earned_cents, default: 0
      t.string :interest_earned_currency, default: "PHP", null: false
      t.string :status, default: "pending", null: false
      t.datetime :opened_at
      t.datetime :closed_at

      t.timestamps
    end
  end
end
