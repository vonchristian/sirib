module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    before_action :require_active_status
    before_action :refresh_session_activity
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
      skip_before_action :require_active_status, **options
    end
  end

  private

    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def require_active_status
      return unless Current.user
      return if Current.user.status_active?

      terminate_session
      redirect_to new_session_path, alert: "Your account has been #{Current.user.status}. Please contact your administrator."
    end

    def refresh_session_activity
      return unless Current.session

      Identity::ContextResolver.new(nil).touch_session!(Current.session)
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      session_record = Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
      return nil unless session_record

      resolver = Identity::ContextResolver.new(session_record.user)
      context = resolver.resolve_with_session(session: session_record)

      unless context[:session_valid]
        session_record.revoke!
        cookies.delete(:session_id)
        return nil
      end

      Current.branch ||= session_record.user.role_assignments.active.first&.branch
      session_record
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || after_sign_in_url
    end

    def after_sign_in_url
      return root_url unless Current.user

      case Current.user.role
      when "manager" then manager_dashboard_url
      when "treasurer" then treasurer_dashboard_url
      when "accountant" then accountant_dashboard_url
      when "loan_officer" then loan_officer_dashboard_url
      else root_url
      end
    end

    def start_new_session_for(user)
      user.sessions.create!(
        user_agent: request.user_agent,
        ip_address: request.remote_ip,
        last_activity_at: Time.current
      ).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session.update!(revoked_at: Time.current) if Current.session
      cookies.delete(:session_id)
    end
end
