module Management
  module Ai
    class DigestsController < Management::Ai::BaseController
      before_action :require_ai_access!
      before_action :set_branch
      before_action :authorize_branch!
      before_action :set_digest, only: [ :show ]

      def index
        @digests = ::Ai::Digest.where(branch: @branch).recent
        @pagy, @digests = pagy(@digests)
      end

      def show
      end

      def latest
        @digest = ::Ai::Digest.where(branch: @branch).recent.first
        if @digest
          render :show
        else
          redirect_to management_ai_digests_path, alert: "No digest available yet."
        end
      end

      private

      def set_digest
        @digest = ::Ai::Digest.find(params[:id])
      end
    end
  end
end
