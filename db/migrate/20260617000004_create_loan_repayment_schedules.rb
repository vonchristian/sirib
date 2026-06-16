class CreateLoanRepaymentSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :loan_repayment_schedules do |t|
      t.references :loan_application, null: false, foreign_key: true
      t.integer :sequence, null: false
      t.date :due_date, null: false
      t.decimal :principal_cents, precision: 15, scale: 2, null: false
      t.string :principal_currency, default: "PHP"
      t.decimal :interest_cents, precision: 15, scale: 2, null: false
      t.string :interest_currency, default: "PHP"
      t.timestamps
    end
    add_index :loan_repayment_schedules, [:loan_application_id, :sequence], unique: true
  end
end
