module Management
  class ExecutiveDashboardController < BaseController
    def index
      @branch_count = Management::Branch.active.count
      @total_members = Membership::Member.count
      @total_assets = Money.new(Accounting::Ledger.where(account_type: :asset).sum(&:balance), "PHP")
      @total_liabilities = Money.new(Accounting::Ledger.where(account_type: :liability).sum(&:balance), "PHP")
      @net_income = Money.new(
        Accounting::Ledger.where(account_type: :revenue).sum(&:balance) -
        Accounting::Ledger.where(account_type: :expense).sum(&:balance),
        "PHP"
      )
      @loan_portfolio = Money.new(Lending::Loan.active.sum(:outstanding_principal_cents), "PHP")
      @savings_deposits = Money.new(Treasury::SavingsAccount.active.sum { |a| a.liability_account&.balance&.cents.to_i }, "PHP")
      @share_capital = Money.new(Equity::Account.sum(:paid_up_shares) * Equity::Product.first&.price_per_share_cents.to_i, "PHP")

      @branch_rankings = Management::Branch.active.by_name.map do |branch|
        snap = branch.performance_snapshots.order(snapshot_date: :desc).first
        metrics = snap&.metrics || {}
        {
          branch: branch,
          total_assets: metrics["loan_portfolio_cents"].to_i,
          loan_portfolio: metrics["loan_portfolio_cents"].to_i,
          savings_deposits: metrics["savings_balance_cents"].to_i,
          member_count: metrics["total_members"].to_i
        }
      end.sort_by { |b| -b[:total_assets] }

      @risk_indicators = Management::RiskIndicator.order(as_of_date: :desc).limit(10)
      @system_health = Management::SystemHealthSnapshot.order(captured_at: :desc).first
    end
  end
end
