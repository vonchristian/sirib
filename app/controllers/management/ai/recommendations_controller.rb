module Management
  module Ai
    class RecommendationsController < Management::Ai::BaseController
      before_action :require_ai_access!
      before_action :set_branch
      before_action :authorize_branch!
      before_action :set_recommendation, only: [ :show, :acknowledge, :dismiss, :complete ]

      def index
        @recommendations = ::Ai::Recommendation.where(branch: @branch)
        @recommendations = @recommendations.where(priority: params[:priority]) if params[:priority].present?
        @recommendations = @recommendations.where(status: params[:status]) if params[:status].present?

        @pagy, @recommendations = pagy(@recommendations.by_priority.recent)
      end

      def show
      end

      def acknowledge
        @recommendation.acknowledge!(Current.user)
        redirect_to management_ai_recommendations_path, notice: "Recommendation acknowledged."
      end

      def dismiss
        @recommendation.dismiss!
        redirect_to management_ai_recommendations_path, notice: "Recommendation dismissed."
      end

      def complete
        @recommendation.complete!
        redirect_to management_ai_recommendations_path, notice: "Recommendation marked as completed."
      end

      private

      def set_recommendation
        @recommendation = ::Ai::Recommendation.find(params[:id])
      end
    end
  end
end
