module TenantContext
  extend ActiveSupport::Concern

  included do
    before_action :set_tenant_from_request
    before_action :require_tenant
    before_action :verify_tenant_access

    helper_method :current_tenant
  end

  private

  def current_tenant
    Current.tenant
  end

  def set_tenant_from_request
    return unless Tenant::Config.enforce_tenant_context

    tenant = Tenant::Resolver.new(request: request, user: Current.user).resolve
    return unless tenant

    Current.tenant = tenant
    Tenant::SchemaManager.switch_to(tenant.schema_name)
  end

  def require_tenant
    return unless Tenant::Config.enforce_tenant_context
    return if current_tenant.present?

    raise ActiveRecord::RecordNotFound
  end

  def verify_tenant_access
    return unless Tenant::Config.enforce_tenant_context
    return unless current_tenant.present? && Current.user.present?
    return if Current.user.cooperative_id == current_tenant.id

    terminate_session

    respond_to do |format|
      format.html { redirect_to new_session_path, alert: "Access denied for this tenant" }
      format.json { render json: { error: "Access denied" }, status: :forbidden }
    end
  end
end
