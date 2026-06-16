class AddDetailsToCooperatives < ActiveRecord::Migration[8.0]
  def change
    add_column :cooperatives, :address, :string
    add_column :cooperatives, :contact_number, :string
    add_column :cooperatives, :registration_number, :string
  end
end
