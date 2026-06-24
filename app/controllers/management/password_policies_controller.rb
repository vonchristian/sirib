module Management
  class PasswordPoliciesController < BaseController
    before_action :set_policy, only: %i[show edit update]

    def index
      @policies = Security::PasswordPolicy.by_cooperative(Current.cooperative).order(:name)
      @pagy, @policies = pagy(@policies)
    end

    def show
    end

    def new
      @policy = Security::PasswordPolicy.new(cooperative: Current.cooperative)
    end

    def create
      @policy = Security::PasswordPolicy.new(policy_params.merge(cooperative: Current.cooperative))

      if @policy.save
        redirect_to management_password_policy_path(@policy), notice: "Password policy created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @policy.update(policy_params)
        redirect_to management_password_policy_path(@policy), notice: "Password policy updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_policy
      @policy = Security::PasswordPolicy.by_cooperative(Current.cooperative).find(params[:id])
    end

    def policy_params
      params.require(:security_password_policy).permit(
        :name, :min_length, :require_uppercase, :require_lowercase,
        :require_digits, :require_symbols, :max_failed_attempts,
        :lockout_duration, :password_expiry_days, :password_history_count, :active
      )
    end
  end
end
