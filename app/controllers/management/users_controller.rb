module Management
  class UsersController < BaseController
    before_action :set_user, only: [ :show, :edit, :update ]
    before_action :require_admin, only: [ :edit, :update ]

    def index
      @pagy, @users = pagy(
        User.order(:email_address)
          .then { |scope| params[:search].present? ? scope.where("email_address ILIKE :q", q: "%#{params[:search]}%") : scope }
      )
    end

    def show
      @role_assignments = @user.role_assignments.active.includes(:role, :branch)
    end

    def edit
    end

    def update
      if @user.update(user_params)
        redirect_to management_user_path(@user), notice: "User was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def require_admin
      unless Current.user.role == "manager"
        redirect_to management_users_path, alert: "Only managers can edit users."
      end
    end

    def user_params
      params.require(:user).permit(:email_address, :password, :password_confirmation)
    end
  end
end
