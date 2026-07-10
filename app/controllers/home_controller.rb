class HomeController < ApplicationController
  MARKETING_ACTIONS = %i[landing tellers loan_officers finance compliance].freeze

  allow_unauthenticated_access only: MARKETING_ACTIONS
  skip_before_action :require_cooperative, only: MARKETING_ACTIONS
  skip_before_action :refresh_session_activity, only: MARKETING_ACTIONS
  layout "landing", only: MARKETING_ACTIONS

  def index
  end

  def landing
    redirect_to dashboard_path if authenticated?
  end

  def tellers
  end

  def loan_officers
  end
end
