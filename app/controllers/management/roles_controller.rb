module Management
  class RolesController < BaseController
    before_action :set_role, only: [ :show, :edit, :update ]

    def index
      @pagy, @roles = pagy(Management::Role.by_rank)
    end

    def show
      @permissions = @role.permissions
    end

    def new
      @role = Management::Role.new
    end

    def create
      @role = Management::Role.new(role_params)
      if @role.save
        redirect_to management_role_path(@role), notice: "Role was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @role.update(role_params)
        redirect_to management_role_path(@role), notice: "Role was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_role
      @role = Management::Role.includes(:permissions).find(params[:id])
    end

    def role_params
      params.require(:management_role).permit(:name, :code, :description, :rank, permission_ids: [])
    end
  end
end
