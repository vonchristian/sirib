class MfaController < ApplicationController
  allow_unauthenticated_access only: %i[challenge verify]
  rate_limit to: 5, within: 10.minutes, only: :verify, with: -> { redirect_to challenge_mfa_path, alert: "Too many attempts. Try again later." }

  before_action :require_mfa_pending_session, only: %i[challenge verify]
  before_action :require_authentication, only: %i[setup enable disable backup_codes step_up_challenge step_up_verify devices revoke_device revoke_all_devices]

  def setup
    @secret = Mfa::TotpService.generate_secret
    @provisioning_uri = Mfa::TotpService.provisioning_uri(@secret, Current.user.email_address)
    session[:mfa_setup_secret] = @secret
  end

  def enable
    code = params[:code]
    secret = session.delete(:mfa_setup_secret)

    unless secret && Mfa::TotpService.verify(secret, code)
      Mfa::TotpService.log_attempt(Current.user, action: "setup_verify", success: false, ip_address: request.remote_ip, user_agent: request.user_agent, failure_reason: "invalid_code")
      flash[:alert] = "Invalid verification code. Please try again."
      redirect_to setup_mfa_path and return
    end

    Current.user.update!(otp_secret: secret, otp_enabled: true, otp_verified_at: Time.current)

    result = Mfa::TotpService.generate_backup_codes
    result[:digests].each { |digest| Current.user.backup_codes.create!(code_digest: digest) }
    @backup_codes = result[:codes]

    Mfa::TotpService.log_attempt(Current.user, action: "setup_complete", success: true, ip_address: request.remote_ip, user_agent: request.user_agent)

    render :backup_codes
  end

  def disable
    Current.user.update!(otp_secret: nil, otp_enabled: false, otp_verified_at: nil)
    Current.user.backup_codes.unused.destroy_all
    Current.user.trusted_devices.destroy_all
    Mfa::TotpService.log_attempt(Current.user, action: "disable", success: true, ip_address: request.remote_ip, user_agent: request.user_agent)
    redirect_to dashboard_settings_path, notice: "Two-factor authentication disabled."
  end

  def challenge
  end

  def verify
    code = params[:code]
    user = User.find(session[:mfa_user_id])

    if Mfa::TotpService.rate_limited?(user)
      Mfa::TotpService.log_attempt(user, action: "login_verify", success: false, ip_address: request.remote_ip, user_agent: request.user_agent, failure_reason: "rate_limited")
      flash.now[:alert] = "Too many attempts. Please try again later."
      render :challenge, status: :too_many_requests and return
    end

    backup_used = false
    verified = if code.length > 7
      Mfa::TotpService.verify_backup_code(code, user)
    else
      user.otp_secret.present? && Mfa::TotpService.verify(user.otp_secret, code)
    end

    if verified
      session[:mfa_user_id] = nil
      session.delete(:mfa_verified)

      start_new_session_for user
      Current.session.verify_mfa!

      fingerprint = Mfa::TotpService.build_device_fingerprint(request)
      Mfa::TotpService.trust_device!(user, fingerprint, ip_address: request.remote_ip, user_agent: request.user_agent)
      Mfa::TotpService.log_attempt(user, action: "login_verify", success: true, ip_address: request.remote_ip, user_agent: request.user_agent, metadata: { backup_used: backup_used })

      redirect_to after_authentication_url
    else
      Mfa::TotpService.log_attempt(user, action: "login_verify", success: false, ip_address: request.remote_ip, user_agent: request.user_agent, failure_reason: "invalid_code")
      flash.now[:alert] = "Invalid verification code."
      render :challenge, status: :unprocessable_entity
    end
  end

  def backup_codes
    @backup_codes = Current.user.backup_codes.unused
  end

  def step_up_challenge
    render layout: false
  end

  def step_up_verify
    code = params[:code]

    if Mfa::TotpService.rate_limited?(Current.user)
      Mfa::TotpService.log_attempt(Current.user, action: "step_up_verify", success: false, ip_address: request.remote_ip, user_agent: request.user_agent, failure_reason: "rate_limited")
      render json: { error: "Too many attempts. Please try again later." }, status: :too_many_requests and return
    end

    verified = if code.length > 7
      Mfa::TotpService.verify_backup_code(code, Current.user)
    else
      Current.user.otp_secret.present? && Mfa::TotpService.verify(Current.user.otp_secret, code)
    end

    if verified
      Current.session.verify_mfa!
      Mfa::TotpService.log_attempt(Current.user, action: "step_up_verify", success: true, ip_address: request.remote_ip, user_agent: request.user_agent)
      render json: { success: true }
    else
      Mfa::TotpService.log_attempt(Current.user, action: "step_up_verify", success: false, ip_address: request.remote_ip, user_agent: request.user_agent, failure_reason: "invalid_code")
      render json: { error: "Invalid verification code." }, status: :unprocessable_entity
    end
  end

  def devices
    @devices = Current.user.trusted_devices.active.order(last_used_at: :desc)
  end

  def revoke_device
    device = Current.user.trusted_devices.find(params[:id])
    device.update!(expires_at: Time.current)
    Mfa::TotpService.log_attempt(Current.user, action: "revoke_device", success: true, ip_address: request.remote_ip, user_agent: request.user_agent, metadata: { device_id: device.id })
    redirect_to devices_mfa_path, notice: "Device revoked."
  end

  def revoke_all_devices
    Mfa::TotpService.log_attempt(Current.user, action: "revoke_all_devices", success: true, ip_address: request.remote_ip, user_agent: request.user_agent)
    Current.user.trusted_devices.update_all(expires_at: Time.current)
    redirect_to devices_mfa_path, notice: "All devices revoked."
  end

  private

  def require_mfa_pending_session
    unless session[:mfa_user_id] && User.exists?(session[:mfa_user_id])
      session[:mfa_user_id] = nil
      redirect_to new_session_path, alert: "Session expired. Please sign in again."
    end
  end
end
