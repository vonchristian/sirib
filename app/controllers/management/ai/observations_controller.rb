module Management
  module Ai
    class ObservationsController < Management::Ai::BaseController
      before_action :require_ai_access!
      before_action :set_branch
      before_action :authorize_branch!
      before_action :set_observation, only: [ :show, :resolve ]

      def index
        @observations = ::Ai::Observation.where(branch: @branch)
        @observations = @observations.where(category: params[:category]) if params[:category].present?
        @observations = @observations.where(severity: params[:severity]) if params[:severity].present?

        if params[:status] == "unresolved"
          @observations = @observations.unresolved
        elsif params[:status] == "resolved"
          @observations = @observations.resolved
        end

        @pagy, @observations = pagy(@observations.by_severity.recent)
      end

      def show
      end

      def resolve
        @observation.resolve!
        redirect_to management_ai_observations_path, notice: "Observation was resolved."
      end

      private

      def set_observation
        @observation = ::Ai::Observation.find(params[:id])
      end
    end
  end
end
