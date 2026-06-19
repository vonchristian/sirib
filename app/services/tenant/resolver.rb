module Tenant
  class Resolver
    class TenantNotResolvedError < StandardError
      def initialize(msg = "No tenant context available")
        super
      end
    end

    RESOLUTION_PRIORITY = %i[subdomain user_context admin_override].freeze

    def initialize(request: nil, user: nil)
      @request = request
      @user = user
    end

    def resolve
      RESOLUTION_PRIORITY.each do |source|
        tenant = send(:"resolve_by_#{source}")
        return tenant if tenant
      end
      nil
    end

    def resolve!
      resolve || (raise TenantNotResolvedError)
    end

    private

    def resolve_by_subdomain
      return nil unless @request
      return nil unless @request.host.present?

      subdomain = extract_subdomain(@request.host)
      return nil unless subdomain.present?

      Cooperative.active.find_by(subdomain: subdomain)
    end

    def resolve_by_user_context
      return nil unless @user

      Cooperative.active.find_by(id: @user.cooperative_id)
    end

    def resolve_by_admin_override
      return nil unless @request
      return nil unless @request.respond_to?(:session)
      return nil unless @request.session[:admin_tenant_id].present?

      Cooperative.active.find_by(id: @request.session[:admin_tenant_id])
    end

    def extract_subdomain(host)
      return nil unless host.present?

      parts = host.split(".")
      return nil if parts.length < 3

      subdomain = parts.first
      return nil if subdomain.blank? || subdomain == "www"

      subdomain
    end
  end
end
