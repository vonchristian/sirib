class DashboardController < ApplicationController
  layout "dashboard"

  def index
    redirect_to role_dashboard_path
  end

  def manager
  end

  def treasurer
  end

  def accountant
  end

  def loan_officer
  end

  def loans
  end

  def payments
  end

  def members
  end

  def tasks
  end

  def reports
  end

  def settings
  end

  private

  def role_dashboard_path
    case Current.user.role
    when "manager" then manager_dashboard_path
    when "treasurer" then treasurer_dashboard_path
    when "accountant" then accountant_dashboard_path
    when "loan_officer" then loan_officer_dashboard_path
    else root_path
    end
  end
end
