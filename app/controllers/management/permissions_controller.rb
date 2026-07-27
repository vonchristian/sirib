module Management
  class PermissionsController < BaseController
    before_action -> { require_permission!(action: :view, subject: :role) }

    def index
      @pagy, @permissions = pagy(Management::Permission.order(:subject, :action))
    end

    def show
      @permission = Management::Permission.find(params[:id])
    end
  end
end
