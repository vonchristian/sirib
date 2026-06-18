module Management
  class ApprovalRequestsController < BaseController
    before_action :set_workflow
    before_action :set_approval_request, only: [:show, :approve, :reject]

    def index
      @approval_requests = @workflow.approval_requests.includes(:requested_by).order(created_at: :desc)
      @pagy, @approval_requests = pagy(@approval_requests)
    end

    def show
      @approvals = @approval_request.approvals.includes(:step, :approver).order("management_approval_workflow_steps.sequence")
    end

    def approve
      unless Management::PermissionService.authorized?(user: Current.user, action: :approve, subject: :approval_request, branch: Current.branch)
        return redirect_to management_approval_workflow_approval_request_path(@workflow, @approval_request), alert: "You are not authorized to approve requests."
      end

      step = @approval_request.workflow.steps.where(approver_role_id: Current.user.role_assignments.active.pluck(:role_id)).first
      unless step
        return redirect_to management_approval_workflow_approval_request_path(@workflow, @approval_request), alert: "No approval step matches your role."
      end

      @approval_request.approvals.create!(
        step: step,
        approver: Current.user,
        status: :approved,
        signed_at: Time.current
      )
      redirect_to management_approval_workflow_approval_request_path(@workflow, @approval_request), notice: "Request was approved."
    end

    def reject
      unless Management::PermissionService.authorized?(user: Current.user, action: :reject, subject: :approval_request, branch: Current.branch)
        return redirect_to management_approval_workflow_approval_request_path(@workflow, @approval_request), alert: "You are not authorized to reject requests."
      end

      step = @approval_request.workflow.steps.where(approver_role_id: Current.user.role_assignments.active.pluck(:role_id)).first
      unless step
        return redirect_to management_approval_workflow_approval_request_path(@workflow, @approval_request), alert: "No approval step matches your role."
      end

      @approval_request.approvals.create!(
        step: step,
        approver: Current.user,
        status: :rejected,
        signed_at: Time.current
      )
      redirect_to management_approval_workflow_approval_request_path(@workflow, @approval_request), notice: "Request was rejected."
    end

    private

    def set_workflow
      @workflow = Management::ApprovalWorkflow.find(params[:approval_workflow_id])
    end

    def set_approval_request
      @approval_request = @workflow.approval_requests.find(params[:id])
    end
  end
end
