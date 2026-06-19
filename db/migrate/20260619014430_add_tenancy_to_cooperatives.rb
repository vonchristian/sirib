class AddTenancyToCooperatives < ActiveRecord::Migration[8.0]
  def change
    add_column :cooperatives, :schema_name, :string
    add_column :cooperatives, :subdomain, :string
    add_column :cooperatives, :status, :string, default: "inactive", null: false
    add_column :cooperatives, :tenant_name, :string
    add_column :cooperatives, :provisioned_at, :datetime
    add_column :cooperatives, :locale, :string, default: "en"
    add_column :cooperatives, :timezone, :string, default: "UTC"

    add_index :cooperatives, :schema_name, unique: true
    add_index :cooperatives, :subdomain, unique: true

    reversible do |dir|
      dir.up do
        Cooperative.where(schema_name: nil).update_all(
          schema_name: "public",
          subdomain: "main",
          status: "active",
          tenant_name: Arel.sql("name"),
          provisioned_at: Time.current
        )
      end
    end
  end
end
