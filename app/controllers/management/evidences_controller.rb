module Management
  class EvidencesController < BaseController
    before_action :set_control

    def index
      @evidences = @control.evidences.by_cooperative(Current.cooperative).by_recent
      @pagy, @evidences = pagy(@evidences)
    end

    def show
      @evidence = @control.evidences.by_cooperative(Current.cooperative).find(params[:id])
    end

    private

    def set_control
      @control = Compliance::Control.by_cooperative(Current.cooperative).find(params[:compliance_control_id])
    end
  end
end
