module Management
  module Ai
    class BaseController < Management::BaseController
      private

      def require_ai_access!
        require_permission!(action: "view", subject: "ai_dashboard")
      end

      def set_branch
        @branch = if params[:branch_id]
          Management::Branch.find(params[:branch_id])
        else
          find_user_branch
        end
      end

      def find_user_branch
        assignments = Current.user.role_assignments.active.where.not(branch_id: nil)
        if assignments.any?
          assignments.first.branch
        else
          nil
        end
      end

      def authorize_branch!
        return unless @branch

        user = Current.user
        is_executive = user.role_assignments.active.any? { |ra| ra.role&.rank.to_i >= 90 }
        return if is_executive

        can_access = user.role_assignments.active.any? { |ra| ra.branch_id == @branch.id || ra.branch_id.nil? }
        unless can_access
          redirect_to management_ai_dashboard_path, alert: "You do not have access to this branch."
        end
      end
    end
  end
end
