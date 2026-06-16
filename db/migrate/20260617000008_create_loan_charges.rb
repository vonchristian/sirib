class CreateLoanCharges < ActiveRecord::Migration[8.0]
  def change
    create_table :loan_charges do |t|
      t.references :loan_product, null: false, foreign_key: true
      t.string :name, null: false
      t.string :charge_type, null: false, default: "fixed"
      t.decimal :value, precision: 10, scale: 2, null: false
      t.timestamps
    end
  end
end
