module StepUpAuthentication
  extend ActiveSupport::Concern

  STEP_UP_ACTIONS = %w[
    treasury/vault_transfers#approve
    treasury/vault_transfers#reject
    treasury/vault_transfers#receive_from_vault
    treasury/vault_transfers#return_to_vault
    treasury/deposits#create
    treasury/savings_accounts/confirm_deposit
    treasury/savings_accounts/confirm_withdraw
    management/configurations#approve
    management/configurations#activate
    management/alerts#resolve
  ].freeze

  included do
    before_action :require_step_up_authentication, if: :step_up_required?
  end

  private

  def step_up_required?
    return false unless Current.user&.otp_enabled
    return false if Current.session&.mfa_verified?

    action_requires_step_up?
  end

  def action_requires_step_up?
    controller_path = params[:controller]
    action_name = params[:action]
    STEP_UP_ACTIONS.include?("#{controller_path}##{action_name}")
  end

  def require_step_up_authentication
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("modal", partial: "mfa/step_up_modal")
      end
      format.json do
        render json: { error: "Step-up authentication required", step_up_url: step_up_challenge_mfa_path }, status: :unauthorized
      end
      format.html do
        redirect_to step_up_challenge_mfa_path, alert: "Please verify your identity to continue."
      end
    end
  end
end
