require "rails_helper"

RSpec.describe Tenant::SchemaManager, type: :service do
  describe ".create_schema" do
    after do
      described_class.drop_schema("test_tenant_coop_a")
    end

    it "creates a new PostgreSQL schema" do
      described_class.create_schema("test_tenant_coop_a")
      expect(described_class.schema_exists?("test_tenant_coop_a")).to be true
    end

    it "is idempotent" do
      described_class.create_schema("test_tenant_coop_a")
      expect do
        described_class.create_schema("test_tenant_coop_a")
      end.not_to raise_error
    end
  end

  describe ".drop_schema" do
    before do
      described_class.create_schema("test_tenant_coop_a")
    end

    after do
      described_class.drop_schema("test_tenant_coop_a")
    end

    it "drops a schema" do
      described_class.drop_schema("test_tenant_coop_a")
      expect(described_class.schema_exists?("test_tenant_coop_a")).to be false
    end

    it "does not drop the public schema" do
      expect do
        described_class.drop_schema("public")
      end.not_to raise_error
    end
  end

  describe ".switch_to" do
    after do
      described_class.switch_to_shared
    end

    it "switches the search_path to the given schema" do
      described_class.create_schema("test_tenant_coop_a")
      described_class.switch_to("test_tenant_coop_a")
      expect(described_class.current_schema).to eq("test_tenant_coop_a")
    end
  end

  describe ".within_schema" do
    it "executes block in the target schema and restores" do
      described_class.create_schema("test_tenant_coop_a")
      described_class.within_schema("test_tenant_coop_a") do
        expect(described_class.current_schema).to eq("test_tenant_coop_a")
      end
      expect(described_class.current_schema).to eq("public")
    end

    it "restores even when block raises" do
      described_class.create_schema("test_tenant_coop_a")
      expect do
        described_class.within_schema("test_tenant_coop_a") { raise "boom" }
      end.to raise_error(RuntimeError, "boom")
      expect(described_class.current_schema).to eq("public")
    end
  end

  describe ".clone_public_tables_to" do
    let(:schema_name) { "test_tenant_coop_b" }

    before do
      described_class.create_schema(schema_name)
    end

    after do
      described_class.drop_schema(schema_name)
    end

    it "clones tables from public schema" do
      described_class.clone_public_tables_to(schema_name)

      result = ActiveRecord::Base.connection.execute(<<-SQL.squish)
        SELECT tablename FROM pg_tables
        WHERE schemaname = #{ActiveRecord::Base.connection.quote(schema_name)}
          AND tablename NOT IN ('schema_migrations', 'ar_internal_metadata')
      SQL

      expect(result.count).to be > 0
    end
  end

  describe ".public_tables" do
    it "returns non-shared table names from public schema" do
      tables = described_class.public_tables
      expect(tables).to include("accounts", "ledgers", "entries")
      expect(tables).not_to include("cooperatives", "users")
    end
  end

  describe ".shared_tables" do
    it "lists tables that remain in public schema" do
      expect(described_class.shared_tables).to include("cooperatives", "users", "sessions")
    end
  end
end
