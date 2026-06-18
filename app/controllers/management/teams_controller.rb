module Management
  class TeamsController < BaseController
    before_action :set_team, only: [:show, :edit, :update]

    def index
      @teams = Management::Team.all
      @teams = @teams.where(department_id: params[:department_id]) if params[:department_id].present?
      @pagy, @teams = pagy(@teams.order(:name))
    end

    def show
    end

    def new
      @team = Management::Team.new
    end

    def create
      @team = Management::Team.new(team_params)
      if @team.save
        redirect_to management_team_path(@team), notice: "Team was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @team.update(team_params)
        redirect_to management_team_path(@team), notice: "Team was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_team
      @team = Management::Team.find(params[:id])
    end

    def team_params
      params.require(:management_team).permit(:name, :department_id, :description)
    end
  end
end
