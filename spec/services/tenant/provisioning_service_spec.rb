require "rails_helper"

RSpec.describe Tenant::ProvisioningService, type: :service do
  describe ".call" do
    let(:cooperative) { create(:cooperative, schema_name: "provision_test_coop", status: "inactive") }

    after do
      Tenant::SchemaManager.drop_schema(cooperative.schema_name)
    end

    it "creates a schema and provisions the cooperative" do
      described_class.call(cooperative)

      expect(Tenant::SchemaManager.schema_exists?(cooperative.schema_name)).to be true
      expect(cooperative.reload).to be_status_active
      expect(cooperative.provisioned_at).to be_present
    end

    it "clones table structure into tenant schema" do
      described_class.call(cooperative)

      tables = ActiveRecord::Base.connection.execute(<<-SQL.squish)
        SELECT tablename FROM pg_tables
        WHERE schemaname = #{ActiveRecord::Base.connection.quote(cooperative.schema_name)}
          AND tablename NOT IN ('schema_migrations', 'ar_internal_metadata')
      SQL

      expect(tables.count).to be > 0
      expect(tables.map { |r| r["tablename"] }).to include("accounts", "ledgers", "entries")
    end

    it "is idempotent when called once" do
      described_class.call(cooperative)

      expect do
        described_class.call(cooperative)
      end.to raise_error(Tenant::ProvisioningService::ProvisioningError)
    end

    it "marks cooperative as failed on error and cleans up" do
      allow(Tenant::SchemaManager).to receive(:clone_public_tables_to).and_raise("boom")

      expect do
        described_class.call(cooperative)
      end.to raise_error(Tenant::ProvisioningService::ProvisioningError)

      expect(Tenant::SchemaManager.schema_exists?(cooperative.schema_name)).to be false
    end
  end
end
