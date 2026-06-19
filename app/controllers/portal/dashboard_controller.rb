class Portal::DashboardController < Portal::BaseController
  def index
    @member = Current.member
    @savings_accounts = Treasury::SavingsAccount.where(depositor_id: @member.id, depositor_type: "Membership::Member").includes(:savings_product, :liability_account).active.by_latest
    @share_capital_accounts = Equity::Account.where(member: @member).includes(:share_product).active.by_latest
    @loans = Lending::Loan.where(member: @member).includes(:loan_product, :loan_application).active.order(created_at: :desc)
    @announcements = announcements_scope.limit(5)
    @total_savings = @savings_accounts.sum { |a| a.balance.cents }
    @total_share_capital = @share_capital_accounts.sum { |a| a.shares_owned * a.share_product.price_per_share_cents }
    @total_loans = @loans.sum { |l| l.outstanding_principal_cents }
  end

  private

  def announcements_scope
    Portal::Announcement.published.for_cooperative(current_cooperative).by_latest
  end

  def current_cooperative
    Current.tenant
  end
end