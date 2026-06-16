class CreateMembershipApplications < ActiveRecord::Migration[8.0]
  def change
    create_table :membership_applications do |t|
      t.string :uuid, null: false
      t.references :cooperative, null: false, foreign_key: true
      t.string :status, default: "draft", null: false
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.string :suffix
      t.date :birth_date
      t.string :gender
      t.string :civil_status
      t.string :mobile_number
      t.string :email_address
      t.string :house_street
      t.string :barangay
      t.string :city
      t.string :province
      t.string :region
      t.string :zip_code
      t.jsonb :identifications, default: []
      t.text :signature_data
      t.text :profile_image_data
      t.timestamps
    end

    add_index :membership_applications, :uuid, unique: true
  end
end
