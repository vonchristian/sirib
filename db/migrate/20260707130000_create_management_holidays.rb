class CreateManagementHolidays < ActiveRecord::Migration[8.0]
  def change
    create_table :management_holidays do |t|
      t.references :cooperative, null: false, foreign_key: true
      t.date :date, null: false
      t.string :name, null: false
      t.boolean :recurring, default: false, null: false
      t.timestamps
    end

    add_index :management_holidays, [ :cooperative_id, :date ], unique: true
  end
end
