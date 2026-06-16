class CreateTreasuryTimeDepositProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :treasury_time_deposit_products do |t|
      t.string :name, null: false
      t.text :description
      t.integer :minimum_deposit_cents, null: false, default: 0
      t.string :minimum_deposit_currency, default: "PHP", null: false
      t.decimal :interest_rate, precision: 8, scale: 4, null: false
      t.integer :term_in_days, null: false
      t.string :status, default: "active", null: false

      t.timestamps
    end
  end
end
