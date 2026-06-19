class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new
  end

  def create
    user = find_user_by_credential(params)

    if user.nil?
      redirect_to(new_session_path, alert: "Try another email address or password.") && return
    end

    unless user.status_active?
      Management::AuditLogService.run!(
        action: "login_blocked",
        actor: user,
        metadata: { reason: "account_#{user.status}", ip_address: request.remote_ip }
      )
      redirect_to(new_session_path, alert: "Your account has been #{user.status}. Please contact your administrator.") && return
    end

    unless user.authenticate(params[:password])
      redirect_to(new_session_path, alert: "Try another email address or password.") && return
    end

    Management::AuditLogService.run!(
      action: "login_success",
      actor: user,
      metadata: { ip_address: request.remote_ip, user_agent: request.user_agent }
    )

    if user.otp_enabled
      fingerprint = Mfa::TotpService.build_device_fingerprint(request)

      if Mfa::TotpService.device_trusted?(user, fingerprint)
        start_new_session_for user
        Current.session.verify_mfa!
        Mfa::TotpService.log_attempt(user, action: "login_trusted_device", success: true, ip_address: request.remote_ip, user_agent: request.user_agent)
        redirect_to(after_authentication_url) && return
      end

      session[:mfa_user_id] = user.id
      redirect_to(challenge_mfa_path) && return
    end

    start_new_session_for user
    redirect_to after_authentication_url
  end

  def destroy
    Management::AuditLogService.run!(
      action: "logout",
      actor: Current.user,
      metadata: { ip_address: request.remote_ip }
    )
    terminate_session
    redirect_to new_session_path
  end

  private

  def find_user_by_credential(params)
    if params[:employee_id].present?
      User.find_by(employee_id: params[:employee_id])
    elsif params[:email_address].present?
      User.find_by(email_address: params[:email_address]) ||
        User.find_by(employee_id: params[:email_address])
    end
  end
end
