class CreateEntryTemplatesInTenantSchemas < ActiveRecord::Migration[8.0]
  TENANT_PREFIX = "tenant_"

  def up
    drop_table :entry_template_lines if table_exists?(:entry_template_lines)
    drop_table :entry_templates if table_exists?(:entry_templates)

    tenant_schemas.each do |schema|
      Tenant::SchemaManager.within_schema(schema) do
        next if table_exists?(:entry_templates)

        create_table :entry_templates do |t|
          t.string :name, null: false
          t.text :description
          t.boolean :is_active, default: true
          t.references :entry, foreign_key: true
          t.timestamps
        end
        add_index :entry_templates, :name

        create_table :entry_template_lines do |t|
          t.references :entry_template, null: false, foreign_key: true
          t.references :account, null: false, foreign_key: true
          t.string :direction, null: false
          t.string :amount_mode, default: "variable"
          t.decimal :fixed_amount, precision: 16, scale: 2
          t.integer :sequence_index, default: 0
          t.timestamps
        end
        add_index :entry_template_lines, :sequence_index
      end
    end
  end

  def down
    tenant_schemas.each do |schema|
      Tenant::SchemaManager.within_schema(schema) do
        drop_table :entry_template_lines if table_exists?(:entry_template_lines)
        drop_table :entry_templates if table_exists?(:entry_templates)
      end
    end
  end

  private

  def tenant_schemas
    execute(<<-SQL.squish).map { |r| r["schema_name"] }
      SELECT schema_name
      FROM information_schema.schemata
      WHERE schema_name LIKE '#{TENANT_PREFIX}%'
      ORDER BY schema_name
    SQL
  end
end
