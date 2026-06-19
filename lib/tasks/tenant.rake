namespace :tenant do
  desc "Run migrations across all tenant schemas"
  task migrate: :environment do
    Tenant::SchemaManager.switch_to_shared

    TenantMigrationAudit.create_or_update_audit_table!

    Cooperative.active.provisioned.find_each do |cooperative|
      puts "Migrating tenant: #{cooperative.name} (#{cooperative.schema_name})"

      TenantMigrationAudit.record_run(cooperative) do
        Tenant::SchemaManager.run_migrations_in(cooperative.schema_name)
      end
    rescue => e
      puts "  FAILED: #{e.message}"
    end

    Tenant::SchemaManager.switch_to_shared
  end

  desc "Rollback on a specific tenant schema (use SCHEMA=tenant_xxx and STEP=n)"
  task rollback: :environment do
    schema_name = ENV["SCHEMA"]
    step = (ENV["STEP"] || 1).to_i

    unless schema_name
      puts "Usage: SCHEMA=tenant_xxx STEP=1"
      exit 1
    end

    Tenant::SchemaManager.switch_to(schema_name)
    migration_context = ActiveRecord::MigrationContext.new(
      ActiveRecord::Migrator.migrations_paths,
      ActiveRecord::SchemaMigration
    )
    migration_context.rollback(step)
    Tenant::SchemaManager.switch_to_shared
  end

  desc "Provision a new tenant by cooperative ID: COOP_ID=123"
  task provision: :environment do
    coop_id = ENV["COOP_ID"]
    unless coop_id
      puts "Usage: COOP_ID=123"
      exit 1
    end

    cooperative = Cooperative.find(coop_id)
    Tenant::ProvisioningService.call(cooperative)
    puts "Provisioned: #{cooperative.name}"
  end

  desc "List all tenant schemas and their status"
  task list: :environment do
    puts "%-30s %-25s %-12s %s" % %w[Name Schema Status Provisioned]
    puts "-" * 90
    Cooperative.order(:name).find_each do |c|
      puts "%-30s %-25s %-12s %s" % [
        c.name.truncate(29),
        c.schema_name.truncate(24),
        c.status,
        c.provisioned_at&.to_date || "-"
      ]
    end
  end
end

class TenantMigrationAudit
  def self.create_or_update_audit_table!
    return if ActiveRecord::Base.connection.table_exists?("tenant_migration_audits")

    ActiveRecord::Base.connection.create_table :tenant_migration_audits do |t|
      t.string :schema_name, null: false
      t.string :migration_version
      t.string :status, default: "pending"
      t.text :error_message
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps
    end

    ActiveRecord::Base.connection.add_index :tenant_migration_audits, [ :schema_name, :migration_version ], unique: true, name: "idx_tenant_migration_audits_unique"
  end

  def self.record_run(cooperative)
    start = Time.current
    yield
    completed = Time.current

    ActiveRecord::Base.connection.execute(<<-SQL.squish)
      INSERT INTO tenant_migration_audits (schema_name, migration_version, status, started_at, completed_at, created_at, updated_at)
      VALUES (#{ActiveRecord::Base.connection.quote(cooperative.schema_name)}, #{ActiveRecord::Base.connection.quote(current_migration_version)}, 'success', #{ActiveRecord::Base.connection.quote(start)}, #{ActiveRecord::Base.connection.quote(completed)}, NOW(), NOW())
    SQL
  rescue => e
    ActiveRecord::Base.connection.execute(<<-SQL.squish)
      INSERT INTO tenant_migration_audits (schema_name, migration_version, status, error_message, started_at, completed_at, created_at, updated_at)
      VALUES (#{ActiveRecord::Base.connection.quote(cooperative.schema_name)}, #{ActiveRecord::Base.connection.quote(current_migration_version)}, 'failed', #{ActiveRecord::Base.connection.quote(e.message)}, #{ActiveRecord::Base.connection.quote(start)}, NOW(), NOW())
    SQL
    raise
  end

  def self.current_migration_version
    ActiveRecord::Base.connection.migration_context.current_version.to_s
  rescue
    "unknown"
  end
end
