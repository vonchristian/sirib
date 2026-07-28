class HomeController < ApplicationController
  allow_unauthenticated_access only: [ :landing ]
  layout "application"

  def landing
    redirect_to dashboard_path if authenticated?
  end
end
