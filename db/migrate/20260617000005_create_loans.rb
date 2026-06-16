class CreateLoans < ActiveRecord::Migration[8.0]
  def change
    create_table :loans do |t|
      t.references :loan_application, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.references :loan_product, null: false, foreign_key: true
      t.decimal :principal_cents, precision: 15, scale: 2, null: false
      t.string :principal_currency, default: "PHP"
      t.decimal :interest_rate, precision: 5, scale: 2, null: false
      t.string :interest_calculation, null: false
      t.integer :term_months, null: false
      t.decimal :outstanding_principal_cents, precision: 15, scale: 2, null: false
      t.string :outstanding_principal_currency, default: "PHP"
      t.string :status, null: false, default: "active"
      t.date :disbursed_at
      t.string :reference_number
      t.timestamps
    end
    add_index :loans, :reference_number, unique: true
  end
end
