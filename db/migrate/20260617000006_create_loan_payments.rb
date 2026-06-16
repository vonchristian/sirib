class CreateLoanPayments < ActiveRecord::Migration[8.0]
  def change
    create_table :loan_payments do |t|
      t.references :loan, null: false, foreign_key: true
      t.string :reference_number, null: false
      t.decimal :amount_cents, precision: 15, scale: 2, null: false
      t.string :amount_currency, default: "PHP"
      t.decimal :principal_cents, precision: 15, scale: 2, null: false, default: 0
      t.string :principal_currency, default: "PHP"
      t.decimal :interest_cents, precision: 15, scale: 2, null: false, default: 0
      t.string :interest_currency, default: "PHP"
      t.decimal :penalty_cents, precision: 15, scale: 2, null: false, default: 0
      t.string :penalty_currency, default: "PHP"
      t.date :payment_date, null: false
      t.references :entry, foreign_key: { to_table: :entries }
      t.timestamps
    end
    add_index :loan_payments, :reference_number, unique: true
  end
end
