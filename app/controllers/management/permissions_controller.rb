module Management
  class PermissionsController < BaseController
    def index
      @pagy, @permissions = pagy(Management::Permission.order(:subject, :action))
    end

    def show
      @permission = Management::Permission.find(params[:id])
    end
  end
end
