class CreateMemberAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :member_addresses do |t|
      t.references :member, null: false, foreign_key: true
      t.string :house_street, null: false
      t.string :barangay, null: false
      t.string :city, null: false
      t.string :province, null: false
      t.string :region, null: false
      t.string :zip_code

      t.timestamps
    end
  end
end
