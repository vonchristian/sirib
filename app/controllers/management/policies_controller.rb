module Management
  class PoliciesController < BaseController
    before_action :set_policy, only: [:show, :edit, :update, :activate, :deactivate]

    def index
      @policies = Management::Policy.by_category
      @policies = @policies.where(category: params[:category]) if params[:category].present?
      @pagy, @policies = pagy(@policies)
    end

    def show
    end

    def new
      @policy = Management::Policy.new
      @policy.rules.build
    end

    def create
      @policy = Management::Policy.new(policy_params)
      @policy.created_by = Current.user
      if @policy.save
        redirect_to management_policy_path(@policy), notice: "Policy was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @policy.update(policy_params)
        redirect_to management_policy_path(@policy), notice: "Policy was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def activate
      @policy.update!(status: :active)
      redirect_to management_policy_path(@policy), notice: "Policy was activated."
    end

    def deactivate
      @policy.update!(status: :inactive)
      redirect_to management_policy_path(@policy), notice: "Policy was deactivated."
    end

    private

    def set_policy
      @policy = Management::Policy.includes(:rules).find(params[:id])
    end

    def policy_params
      params.require(:management_policy).permit(:name, :code, :category, :description, :status, :target_entity_type, :target_entity_id,
        rules_attributes: [:id, :field, :operator, :value, :effect, :_destroy])
    end
  end
end
