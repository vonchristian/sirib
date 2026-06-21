class Portal::SessionsController < Portal::BaseController
  allow_unauthenticated_portal_access only: %i[new create]
  skip_before_action :require_cooperative, only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_portal_session_url, alert: "Try again later." }

  def new
    redirect_to portal_dashboard_path if portal_authenticated?
  end

  def create
    member = find_member_by_credential(params)

    if member.nil?
      redirect_to(new_portal_session_path, alert: "Invalid member ID or password.") && return
    end

    unless member.portal_active?
      redirect_to(new_portal_session_path, alert: "Your portal account is not active. Please contact your cooperative.") && return
    end

    unless member.authenticate(params[:password])
      redirect_to(new_portal_session_path, alert: "Invalid member ID or password.") && return
    end

    if member.otp_enabled
      session[:portal_mfa_member_id] = member.id
      redirect_to portal_mfa_challenge_path && return
    end

    start_new_portal_session_for member
    member.update!(last_login_at: Time.current)
    redirect_to after_portal_auth_url
  end

  def destroy
    terminate_portal_session
    redirect_to new_portal_session_path, notice: "Signed out successfully."
  end

  private

  def find_member_by_credential(params)
    identifier = params[:member_identifier].presence || params[:email_address].presence
    return nil unless identifier

    member = Membership::Member.find_by(member_identifier: identifier)
    member ||= Membership::Member.find_by(email_address: identifier)
    member
  end
end