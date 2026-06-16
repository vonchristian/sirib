class CreateLoanApplications < ActiveRecord::Migration[8.0]
  def change
    create_table :loan_applications do |t|
      t.references :cooperative, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.references :loan_product, null: false, foreign_key: true
      t.string :uuid, null: false
      t.string :status, null: false, default: "draft"
      t.integer :current_step, default: 0
      t.decimal :amount_cents, precision: 15, scale: 2, null: false
      t.string :amount_currency, default: "PHP"
      t.decimal :interest_rate, precision: 5, scale: 2, null: false
      t.integer :term_months, null: false
      t.date :submitted_at
      t.date :approved_at
      t.text :notes
      t.jsonb :sources_of_income, default: []
      t.timestamps
    end
    add_index :loan_applications, :uuid, unique: true
  end
end
