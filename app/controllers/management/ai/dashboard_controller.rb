module Management
  module Ai
    class DashboardController < Management::Ai::BaseController
      before_action :require_ai_access!
      before_action :set_branch
      before_action :authorize_branch!, :validate_branch

      def index
        @today_digest = ::Ai::Digest.today.where(branch: @branch).recent.first
        @critical_observations = ::Ai::Observation.unresolved.where(branch: @branch, severity: "critical").by_severity.recent.limit(5)
        @active_recommendations = ::Ai::Recommendation.active.where(branch: @branch).by_priority.recent.limit(5)
        @observations = ::Ai::Observation.unresolved.where(branch: @branch).by_severity.recent.limit(10)
        @recent_recommendations = ::Ai::Recommendation.active.where(branch: @branch).by_priority.recent.limit(10)
      end

      private

      def validate_branch
        unless @branch
          redirect_to management_dashboard_path, alert: "No branch assigned to your account."
        end
      end
    end
  end
end
