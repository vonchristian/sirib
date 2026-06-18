module Management
  class ApprovalWorkflowService < ActiveInteraction::Base
    object :requestable
    object :workflow, class: "Management::ApprovalWorkflow"
    object :requested_by, class: "User"
    hash :context, default: {}

    def execute
      steps = workflow.steps
      return errors.add(:base, "Workflow has no steps") if steps.empty?

      start_step = find_starting_step(steps)

      unless start_step
        start_step = steps.first
      end

      approval_request = Management::ApprovalRequest.create!(
        requestable: requestable,
        workflow: workflow,
        requested_by: requested_by,
        status: "pending",
        current_step: start_step.sequence,
        reason: context[:reason]
      )

      compose(Management::AuditLogService, action: "approval_request_created",
        auditable: approval_request,
        actor: requested_by,
        metadata: { workflow: workflow.code, step: start_step.sequence })

      approval_request
    end

    def self.resolve(request, approver, status:, comment: nil)
      ActiveRecord::Base.transaction do
        current_step = request.workflow.steps.find_by!(sequence: request.current_step)

        approval = Management::Approval.create!(
          approval_request: request,
          step: current_step,
          approver: approver,
          status: status,
          comment: comment,
          signed_at: Time.current
        )

        if status == "approved"
          next_step = request.workflow.steps.where("sequence > ?", request.current_step).first

          if next_step
            request.update!(current_step: next_step.sequence)
          else
            request.update!(status: "approved")
            request.requestable.approve!(approver) if request.requestable.respond_to?(:approve!)
          end
        else
          request.update!(status: "rejected")
          request.requestable.reject!(approver) if request.requestable.respond_to?(:reject!)
        end

        Management::AuditLogService.run!(action: "approval_#{status}",
          auditable: request,
          actor: approver,
          metadata: { step: current_step.sequence, comment: comment })

        approval
      end
    end

    private

    def find_starting_step(steps)
      amount = context[:amount_cents]
      return steps.first unless amount

      steps.detect do |step|
        min = step.threshold_cents_min || 0
        max = step.threshold_cents_max || Float::INFINITY
        amount >= min && amount <= max
      end
    end
  end
end
