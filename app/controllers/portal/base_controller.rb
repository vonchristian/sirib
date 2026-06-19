class Portal::BaseController < ApplicationController
  include PortalAuthentication

  layout "portal"

  # Skip admin authentication — portal uses its own authentication
  skip_before_action :require_authentication
  skip_before_action :require_active_status
  skip_before_action :refresh_session_activity
  skip_before_action :set_current_cash_session
  skip_before_action :set_current_branch

  private

  def require_portal_active_status
    return unless Current.member
    return if Current.member.portal_active?

    terminate_portal_session
    redirect_to new_portal_session_path, alert: "Your account has been suspended. Please contact your cooperative."
  end
end
