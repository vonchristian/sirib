# Tenant configuration
#
# Controls how multi-tenancy behaves across environments.

module Tenant
  module Config
    mattr_accessor :enforce_tenant_context
    self.enforce_tenant_context = ENV.fetch("ENFORCE_TENANT_CONTEXT", (!Rails.env.test?).to_s) == "true"

    mattr_accessor :allow_public_schema_access
    self.allow_public_schema_access = Rails.env.development? || Rails.env.test?
  end
end

# Register tenant middleware
require Rails.root.join("app/middleware/tenant_resolver")
Rails.application.config.middleware.use(TenantResolver)
