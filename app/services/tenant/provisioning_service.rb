module Tenant
  class ProvisioningService
    class ProvisioningError < StandardError; end

    def self.call(cooperative)
      new(cooperative).call
    end

    def initialize(cooperative)
      @cooperative = cooperative
    end

    def call
      validate_cooperative!
      create_schema
      load_schema_structure
      provisioned!
      seed_default_data
      @cooperative
    rescue => e
      cleanup_on_failure
      raise ProvisioningError, "Failed to provision #{@cooperative.name}: #{e.message}"
    end

    private

    def validate_cooperative!
      raise ProvisioningError, "Cooperative has no schema_name" if @cooperative.schema_name.blank?
      raise ProvisioningError, "Schema #{@cooperative.schema_name} already exists" if SchemaManager.schema_exists?(@cooperative.schema_name)
    end

    def create_schema
      SchemaManager.create_schema(@cooperative.schema_name)
    end

    def load_schema_structure
      SchemaManager.clone_public_tables_to(@cooperative.schema_name)
    end

    def provisioned!
      @cooperative.update!(
        status: "active",
        provisioned_at: Time.current
      )
    end

    def seed_default_data
      SchemaManager.within_schema(@cooperative.schema_name) do
        seed_chart_of_accounts
        seed_loan_products
        seed_savings_products
        seed_management_structure
      end
    end

    def seed_chart_of_accounts
      load_db_seed("chart_of_accounts")
    end

    def seed_loan_products
      load_db_seed("loan_products")
    end

    def seed_savings_products
      load_db_seed("savings_products")
    end

    def seed_management_structure
      load_db_seed("management")
    end

    def cleanup_on_failure
      SchemaManager.drop_schema(@cooperative.schema_name) if @cooperative.schema_name.present?
    rescue => e
      Rails.logger.error("Tenant cleanup failed: #{e.message}")
    end

    def load_db_seed(seed_file)
      load Rails.root.join("db/seeds/#{seed_file}.rb")
    rescue LoadError, Errno::ENOENT
      Rails.logger.warn("Seed file db/seeds/#{seed_file}.rb not found, skipping")
    end
  end
end
