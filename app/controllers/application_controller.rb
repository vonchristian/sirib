class ApplicationController < ActionController::Base
  include Authentication
  include CooperativeContext
  include Pagy::Backend

  before_action :set_current_cash_session
  before_action :set_current_branch

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def set_current_cash_session
    return unless Current.user

    Current.cash_session = Current.user.current_cash_session
  end

  def set_current_branch
    return unless Current.user

    Current.branch = Current.user.role_assignments.active.first&.branch
  end
end
