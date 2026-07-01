module Management
  class BranchesController < BaseController
    before_action :set_branch, only: [ :show, :edit, :update ]

    def index
      @pagy, @branches = pagy(
        Management::Branch.by_name
          .then { |scope| params[:search].present? ? scope.where("name ILIKE :q OR code ILIKE :q", q: "%#{params[:search]}%") : scope }
      )
    end

    def show
      @departments = @branch.departments.by_name
      @snapshot = @branch.performance_snapshots.order(snapshot_date: :desc).first
    end

    def new
      @branch = Management::Branch.new
    end

    def create
      @branch = Management::Branch.new(branch_params)
      if @branch.save
        redirect_to management_branch_path(@branch), notice: "Branch was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @branch.update(branch_params)
        redirect_to management_branch_path(@branch), notice: "Branch was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_branch
      @branch = Management::Branch.find(params[:id])
    end

    def branch_params
      params.require(:management_branch).permit(:name, :code, :status, :parent_id, :cooperative_id, :address, :phone, :email)
    end
  end
end
