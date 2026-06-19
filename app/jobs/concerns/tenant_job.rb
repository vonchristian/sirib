module TenantJob
  extend ActiveSupport::Concern

  included do
    around_perform :switch_to_tenant_schema
  end

  class_methods do
    def perform_later(*args, tenant: nil, **kwargs)
      if tenant
        kwargs[:tenant_id] = tenant.is_a?(Cooperative) ? tenant.id : tenant
      end
      super(*args, **kwargs)
    end
  end

  private

  def switch_to_tenant_schema
    tenant = resolve_tenant
    if tenant
      Tenant::SchemaManager.switch_to(tenant.schema_name)
    end
    yield
  ensure
    Tenant::SchemaManager.switch_to_shared
  end

  def resolve_tenant
    tenant_id = arguments.last.is_a?(Hash) ? arguments.last[:tenant_id] : nil
    return nil unless tenant_id

    @_tenant ||= Cooperative.active.find_by(id: tenant_id)
  end
end
