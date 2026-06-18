module Management
  class BaseController < ApplicationController
    layout "shell"

    private

    def require_permission!(action:, subject:)
      unless Management::PermissionService.authorized?(user: Current.user, action: action, subject: subject, branch: Current.branch)
        redirect_to management_dashboard_path, alert: "You are not authorized to perform this action."
      end
    end
  end
end
