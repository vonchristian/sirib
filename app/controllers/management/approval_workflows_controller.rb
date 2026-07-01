module Management
  class ApprovalWorkflowsController < BaseController
    before_action :set_workflow, only: [ :show, :edit, :update ]

    def index
      @pagy, @workflows = pagy(Management::ApprovalWorkflow.includes(:steps).order(:name))
    end

    def show
      @pending_requests = @workflow.approval_requests.pending.includes(:requested_by).order(created_at: :desc).limit(10)
    end

    def new
      @workflow = Management::ApprovalWorkflow.new
      @workflow.steps.build
    end

    def create
      @workflow = Management::ApprovalWorkflow.new(workflow_params)
      if @workflow.save
        redirect_to management_approval_workflow_path(@workflow), notice: "Workflow was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @workflow.update(workflow_params)
        redirect_to management_approval_workflow_path(@workflow), notice: "Workflow was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_workflow
      @workflow = Management::ApprovalWorkflow.includes(:steps).find(params[:id])
    end

    def workflow_params
      params.require(:management_approval_workflow).permit(:name, :code, :category, :description,
        steps_attributes: [ :id, :sequence, :approver_role_id, :approver_user_id, :threshold_cents_min, :threshold_cents_max, :_destroy ])
    end
  end
end
