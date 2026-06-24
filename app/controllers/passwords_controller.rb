class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to new_session_path, notice: "Password reset instructions sent (if user with that email address exists)."
  end

  def edit
  end

  def update
    password = params[:password]
    result = Security::PasswordPolicyService.evaluate(password: password, user: @user, cooperative: @user.cooperative)

    unless result.valid?
      redirect_to edit_password_path(params[:token]), alert: result.errors.first
      return
    end

    if @user.update(password: password, password_confirmation: params[:password_confirmation])
      Security::SessionTrackingService.bump_session_version(@user)
      redirect_to new_session_path, notice: "Password has been reset."
    else
      redirect_to edit_password_path(params[:token]), alert: "Passwords did not match."
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "Password reset link is invalid or has expired."
    end
end
