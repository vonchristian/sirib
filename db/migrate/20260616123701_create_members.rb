class CreateMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :members do |t|
      t.string :first_name, null: false
      t.string :middle_name
      t.string :last_name, null: false
      t.string :suffix
      t.date :birth_date, null: false
      t.string :gender, null: false
      t.string :civil_status, null: false
      t.string :mobile_number, null: false
      t.string :email_address

      t.timestamps
    end

    add_index :members, :email_address, unique: true
  end
end
