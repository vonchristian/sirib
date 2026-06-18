module Management
  class BranchPerformanceService < ActiveInteraction::Base
    object :branch, class: "Management::Branch"
    date :snapshot_date, default: -> { Date.current }

    def execute
      metrics = {
        loan_portfolio_cents: compute_loan_portfolio,
        savings_balance_cents: compute_savings_balance,
        delinquency_rate: compute_delinquency_rate,
        collection_efficiency: compute_collection_efficiency,
        cash_flow_position_cents: compute_cash_flow,
        estimated_profitability_cents: compute_profitability,
        total_members: compute_member_count,
        snapshot_date: snapshot_date
      }

      snapshot = Management::BranchPerformanceSnapshot.find_or_initialize_by(
        branch: branch,
        snapshot_date: snapshot_date
      )
      snapshot.metrics = metrics
      snapshot.save!

      snapshot
    end

    private

    def compute_loan_portfolio
      Lending::Loan.active.sum(:outstanding_principal_cents)
    end

    def compute_savings_balance
      Treasury::SavingsAccount.active.joins(:liability_account).sum("accounts.balance_cents")
    end

    def compute_delinquency_rate
      total = Lending::Loan.active.count
      return 0 if total.zero?
      delinquent = Lending::Loan.active.where(status: "defaulted").count
      (delinquent.to_f / total * 100).round(2)
    end

    def compute_collection_efficiency
      scheduled = Lending::LoanRepaymentSchedule.where("due_date <= ?", snapshot_date)
        .sum(:principal_cents + :interest_cents)
      return 100 if scheduled.zero?
      collected = Lending::LoanPayment.where("payment_date <= ?", snapshot_date)
        .sum(:amount_cents)
      ((collected.to_f / scheduled) * 100).round(2)
    end

    def compute_cash_flow
      Accounting::Account.joins(:ledger)
        .where(ledgers: { account_type: "asset", name: "Cash on Hand" })
        .sum(:balance_cents)
    end

    def compute_profitability
      revenue = Accounting::Account.joins(:ledger)
        .where(ledgers: { account_type: "revenue" })
        .sum(:balance_cents)
      expenses = Accounting::Account.joins(:ledger)
        .where(ledgers: { account_type: "expense" })
        .sum(:balance_cents)
      revenue - expenses
    end

    def compute_member_count
      Member.count
    end
  end
end
