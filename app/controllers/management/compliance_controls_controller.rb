module Management
  class ComplianceControlsController < BaseController
    def index
      @controls = Compliance::Control.by_cooperative(Current.cooperative)
        .includes(:evidences)
        .order(:category, :name)

      @pagy, @controls = pagy(@controls)
    end

    def show
      @control = Compliance::Control.by_cooperative(Current.cooperative).find(params[:id])
      @evidences = @control.evidences.by_cooperative(Current.cooperative).by_recent
    end
  end
end
