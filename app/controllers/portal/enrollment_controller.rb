class Portal::EnrollmentController < Portal::BaseController
  allow_unauthenticated_portal_access only: %i[show complete]

  def show
    @token = params[:token]
    @member = Identity::EnrollmentService.find_member_by_token(@token)

    if @member.nil?
      redirect_to new_portal_session_path, alert: "This enrollment link is invalid or expired."
      return
    end

    if @member.portal_active?
      redirect_to new_portal_session_path, notice: "Your account is already active. Please sign in."
      return
    end

    @secret = Mfa::TotpService.generate_secret
    @provisioning_uri = Mfa::TotpService.provisioning_uri(@secret, @member.email_address || @member.member_identifier)
    session[:portal_enrollment_member_id] = @member.id
    session[:portal_enrollment_secret] = @secret
    session[:portal_enrollment_token] = @token
  end

  MAX_ENROLLMENT_ATTEMPTS = 5
  ENROLLMENT_LOCKOUT_DURATION = 15.minutes

  def complete
    if enrollment_locked_out?
      redirect_to new_portal_session_path, alert: "Too many failed attempts. Please try again in #{lockout_remaining_time} minutes."
      return
    end

    member = Membership::Member.find_by(id: session[:portal_enrollment_member_id])
    token = session[:portal_enrollment_token]
    secret = session[:portal_enrollment_secret]

    if member.nil? || token.nil? || secret.nil?
      redirect_to new_portal_session_path, alert: "Enrollment session expired. Please request a new enrollment link."
      return
    end

    password = params[:password]
    code = params[:code]

    if password.blank? || password.length < 8
      flash.now[:alert] = "Password must be at least 8 characters."
      @secret = secret
      @provisioning_uri = Mfa::TotpService.provisioning_uri(secret, member.email_address || member.member_identifier)
      render :show, status: :unprocessable_entity
      return
    end

    success = Identity::EnrollmentService.complete_enrollment(
      member: member,
      password: password,
      otp_secret: secret,
      otp_code: code
    )

    if success
      clear_enrollment_attempts
      session.delete(:portal_enrollment_member_id)
      session.delete(:portal_enrollment_secret)
      session.delete(:portal_enrollment_token)
      start_new_portal_session_for member
      redirect_to portal_dashboard_path, notice: "Your account is now active. Welcome!"
    else
      track_failed_attempt
      flash.now[:alert] = "Invalid verification code. Please try again."
      @secret = secret
      @provisioning_uri = Mfa::TotpService.provisioning_uri(secret, member.email_address || member.member_identifier)
      render :show, status: :unprocessable_entity
    end
  end

  private

  def enrollment_locked_out?
    return false unless session[:portal_enrollment_failed_attempts].to_i >= MAX_ENROLLMENT_ATTEMPTS
    return false if session[:portal_enrollment_lockout_at].nil?

    lockout_expired_at = session[:portal_enrollment_lockout_at].to_time + ENROLLMENT_LOCKOUT_DURATION
    if Time.current > lockout_expired_at
      clear_enrollment_attempts
      return false
    end
    true
  end

  def lockout_remaining_time
    lockout_expired_at = session[:portal_enrollment_lockout_at].to_time + ENROLLMENT_LOCKOUT_DURATION
    ((lockout_expired_at - Time.current) / 60).ceil
  end

  def track_failed_attempt
    session[:portal_enrollment_failed_attempts] ||= 0
    session[:portal_enrollment_failed_attempts] = session[:portal_enrollment_failed_attempts].to_i + 1
    if session[:portal_enrollment_failed_attempts].to_i >= MAX_ENROLLMENT_ATTEMPTS
      session[:portal_enrollment_lockout_at] = Time.current
    end
  end

  def clear_enrollment_attempts
    session.delete(:portal_enrollment_failed_attempts)
    session.delete(:portal_enrollment_lockout_at)
  end
end
