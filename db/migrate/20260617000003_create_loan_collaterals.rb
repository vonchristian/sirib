class CreateLoanCollaterals < ActiveRecord::Migration[8.0]
  def change
    create_table :loan_collaterals do |t|
      t.references :loan_application, null: false, foreign_key: true
      t.string :category, null: false
      t.string :name
      t.text :description
      t.decimal :assessed_value_cents, precision: 15, scale: 2
      t.string :assessed_value_currency, default: "PHP"
      t.decimal :pin_lat, precision: 10, scale: 7
      t.decimal :pin_lng, precision: 10, scale: 7
      t.string :address
      t.jsonb :details, default: {}
      t.timestamps
    end
  end
end
