module Management
  class UserRoleAssignmentsController < BaseController
    before_action :set_user
    before_action :require_admin

    def new
      @role_assignment = @user.role_assignments.build
    end

    def create
      @role_assignment = @user.role_assignments.build(role_assignment_params)
      if @role_assignment.save
        redirect_to management_user_path(@user), notice: "Role was assigned successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      @role_assignment = @user.role_assignments.find(params[:id])
      @role_assignment.destroy!
      redirect_to management_user_path(@user), notice: "Role assignment was removed."
    end

    private

    def set_user
      @user = User.find(params[:user_id])
    end

    def require_admin
      unless Current.user.role == "manager"
        redirect_to management_users_path, alert: "Only managers can manage role assignments."
      end
    end

    def role_assignment_params
      params.require(:management_role_assignment).permit(:role_id, :branch_id, :department_id, :active_from, :active_until)
    end
  end
end
