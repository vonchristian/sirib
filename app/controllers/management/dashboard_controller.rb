module Management
  class DashboardController < BaseController
    def index
      @total_assets = ledger_balance(:asset)
      @loan_portfolio = Money.new(Lending::Loan.active.sum(:outstanding_principal_cents), "PHP")
      @savings_deposits = Money.new(Treasury::SavingsAccount.active.sum { |a| a.liability_account&.balance&.cents.to_i }, "PHP")
      @share_capital = Money.new(Equity::Account.sum(:paid_up_shares) * Equity::Product.first&.price_per_share_cents.to_i, "PHP")
      @net_income = Money.new(ledger_balance(:revenue).cents - ledger_balance(:expense).cents, "PHP")
      cash_account = Accounting::Account.joins(:ledger).where(ledgers: { account_code: "11110" }).first
      @cash_position = cash_account&.balance || Money.new(0, "PHP")
      @branch_count = Management::Branch.active.count
      @member_count = Member.count
      @recent_alerts = Management::Alert.active.by_severity.limit(5)
      @pending_approvals = Management::ApprovalRequest.pending.includes(:workflow, :requested_by).limit(5)
    end

    private

    def ledger_balance(account_type)
      Money.new(Accounting::Ledger.where(account_type: account_type).sum(&:balance), "PHP")
    end
  end
end
