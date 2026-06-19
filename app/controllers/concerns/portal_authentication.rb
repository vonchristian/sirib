module PortalAuthentication
  extend ActiveSupport::Concern

  PORTAL_IDLE_TIMEOUT = 30.minutes

  included do
    before_action :require_portal_authentication
    before_action :require_portal_active_status
    before_action :refresh_portal_session_activity
    helper_method :portal_authenticated?
  end

  class_methods do
    def allow_unauthenticated_portal_access(**options)
      skip_before_action :require_portal_authentication, **options
      skip_before_action :require_portal_active_status, **options
    end
  end

  private

  def portal_authenticated?
    resume_portal_session
  end

  def require_portal_authentication
    resume_portal_session || request_portal_authentication
  end

  def require_portal_active_status
    return unless Current.member
    return if Current.member.portal_active?

    terminate_portal_session
    redirect_to new_portal_session_path, alert: "Your account has been suspended. Please contact your cooperative."
  end

  def refresh_portal_session_activity
    return unless Current.portal_session&.active?
    Current.portal_session.touch_activity!
  end

  def resume_portal_session
    Current.portal_session ||= find_portal_session_by_cookie
    Current.member = Current.portal_session&.member
    Current.portal_session
  end

  def find_portal_session_by_cookie
    session_record = Portal::Session.find_by(id: cookies.signed[:portal_session_id]) if cookies.signed[:portal_session_id]
    return nil unless session_record
    return nil unless session_record.active?

    if session_record.last_activity_at && session_record.last_activity_at < PORTAL_IDLE_TIMEOUT.ago
      session_record.revoke!
      cookies.delete(:portal_session_id)
      return nil
    end

    session_record
  end

  def request_portal_authentication
    session[:return_to_after_portal_auth] = request.url
    redirect_to new_portal_session_path
  end

  def after_portal_auth_url
    session.delete(:return_to_after_portal_auth) || portal_dashboard_path
  end

  def start_new_portal_session_for(member)
    member.portal_sessions.create!(
      user_agent: request.user_agent,
      ip_address: request.remote_ip,
      last_activity_at: Time.current
    ).tap do |session|
      Current.portal_session = session
      Current.member = member
      cookies.signed.permanent[:portal_session_id] = { value: session.id, httponly: true, same_site: :lax, secure: Rails.env.production? }
    end
  end

  def terminate_portal_session
    Current.portal_session&.update!(revoked_at: Time.current)
    cookies.delete(:portal_session_id)
    Current.portal_session = nil
    Current.member = nil
  end
end
