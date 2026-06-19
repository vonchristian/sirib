class TenantResolver
  TENANT_PARAM_KEY = "tenant_id"
  EXEMPT_PATHS = %w[/up /health /rails/active_storage/blobs /rails/active_storage/representations]

  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    if exempt_path?(request.path) || !Tenant::Config.enforce_tenant_context
      Tenant::SchemaManager.switch_to_shared
      return @app.call(env)
    end

    tenant = resolve_tenant(request)
    if tenant
      Current.tenant = tenant
      Tenant::SchemaManager.switch_to(tenant.schema_name)
    end

    @app.call(env)
  ensure
    Current.reset
    Tenant::SchemaManager.switch_to_shared
  end

  private

  def resolve_tenant(request)
    tenant = Tenant::Resolver.new(request: request, user: Current.user).resolve
    return tenant if tenant

    if request.params[TENANT_PARAM_KEY].present?
      Cooperative.active.find_by(id: request.params[TENANT_PARAM_KEY])
    end
  end

  def exempt_path?(path)
    EXEMPT_PATHS.any? { |p| path.start_with?(p) }
  end
end
