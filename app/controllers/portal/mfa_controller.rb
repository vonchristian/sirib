class Portal::MfaController < Portal::BaseController
  allow_unauthenticated_portal_access only: %i[challenge verify]
  rate_limit to: 5, within: 10.minutes, only: :verify, with: -> { redirect_to portal_mfa_challenge_path, alert: "Too many attempts. Try again later." }

  before_action :require_mfa_pending_member, only: %i[challenge verify]

  def challenge
  end

  def verify
    code = params[:code]
    member = Membership::Member.find(session[:portal_mfa_member_id])

    verified = if code.length > 7
      false
    else
      member.otp_secret.present? && Mfa::TotpService.verify(member.otp_secret, code)
    end

    if verified
      session[:portal_mfa_member_id] = nil
      start_new_portal_session_for member
      member.update!(last_login_at: Time.current)
      redirect_to after_portal_auth_url
    else
      flash.now[:alert] = "Invalid verification code."
      render :challenge, status: :unprocessable_entity
    end
  end

  private

  def require_mfa_pending_member
    unless session[:portal_mfa_member_id] && Membership::Member.exists?(session[:portal_mfa_member_id])
      session[:portal_mfa_member_id] = nil
      redirect_to new_portal_session_path, alert: "Session expired. Please sign in again."
    end
  end
end
