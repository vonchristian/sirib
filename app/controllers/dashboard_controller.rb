class DashboardController < ApplicationController
  layout "dashboard"

  def index
    redirect_to role_dashboard_path
  end

  def manager
    @active_loans_count = Lending::Loan.active.count
    @pending_disbursements_count = Lending::Loan.for_disbursement.count
    todays_collections_cents = Lending::LoanPayment.where(payment_date: Date.current).sum(:amount_cents)
    @todays_collections = Money.new(todays_collections_cents, "PHP")
    @total_members_count = Member.count

    @pending_applications = Lending::LoanApplication.submitted.includes(:member, :loan_product).order(created_at: :desc).limit(4)
    @recent_payments = Lending::LoanPayment.includes(:loan).order(created_at: :desc).limit(3)
    @recent_members = Member.order(created_at: :desc).limit(2)
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
