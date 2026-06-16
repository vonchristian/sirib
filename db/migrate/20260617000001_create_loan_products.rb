class CreateLoanProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :loan_products do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :interest_rate, precision: 5, scale: 2, null: false
      t.string :interest_calculation, null: false, default: "straight_line"
      t.integer :max_term_months, null: false, default: 12
      t.boolean :requires_collateral, default: false
      t.string :status, null: false, default: "active"
      t.timestamps
    end
  end
end
