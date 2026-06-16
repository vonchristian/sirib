class CreateMemberIdentifications < ActiveRecord::Migration[8.0]
  def change
    create_table :member_identifications do |t|
      t.references :member, null: false, foreign_key: true
      t.string :id_type, null: false
      t.string :id_number, null: false

      t.timestamps
    end

    add_index :member_identifications, [:id_type, :id_number], unique: true
  end
end
