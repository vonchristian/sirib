module Management
  class DepartmentsController < BaseController
    before_action :set_department, only: [ :show, :edit, :update ]

    def index
      @departments = Management::Department.by_name
      @departments = @departments.where(branch_id: params[:branch_id]) if params[:branch_id].present?
      @pagy, @departments = pagy(@departments)
    end

    def show
      @teams = @department.teams.by_name
    end

    def new
      @department = Management::Department.new
    end

    def create
      @department = Management::Department.new(department_params)
      if @department.save
        redirect_to management_department_path(@department), notice: "Department was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @department.update(department_params)
        redirect_to management_department_path(@department), notice: "Department was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_department
      @department = Management::Department.find(params[:id])
    end

    def department_params
      params.require(:management_department).permit(:name, :code, :branch_id, :description)
    end
  end
end
