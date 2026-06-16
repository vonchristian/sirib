class CreateTreasurySavingsProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :treasury_savings_products do |t|
      t.string :name, null: false
      t.text :description
      t.string :status, default: "active", null: false
      t.timestamps
    end

    create_table :treasury_savings_product_interest_rates do |t|
      t.references :savings_product, null: false, foreign_key: { to_table: :treasury_savings_products }
      t.decimal :rate, precision: 8, scale: 4, null: false
      t.boolean :current, default: true, null: false
      t.timestamps
    end
  end
end
