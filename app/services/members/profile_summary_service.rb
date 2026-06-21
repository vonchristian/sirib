module Members
  class ProfileSummaryService
    def initialize(member)
      @member = member
    end

    def call
      {
        member: @member,
        savings_count: savings_accounts.count,
        savings_active_count: savings_accounts.active.count,
        savings_balance: savings_accounts.sum { |a| a.balance.cents },
        time_deposit_count: time_deposits.count,
        time_deposit_active_count: time_deposits.select(&:active?).size,
        time_deposit_total: time_deposits.sum { |td| td.amount_cents.to_i },
        loan_count: loans.count,
        loan_active_count: loans.select(&:active?).size,
        loan_outstanding: loans.sum { |l| l.outstanding_principal_cents.to_i },
        share_capital_accounts_count: share_capital_accounts.count,
        share_capital_active_count: share_capital_accounts.active.count,
        share_capital_total_shares: share_capital_accounts.sum(&:shares_owned),
        share_capital_paid_up: share_capital_accounts.sum { |a| a.paid_up_capital.cents }
      }
    end

    private

    def savings_accounts
      @savings_accounts ||= Treasury::SavingsAccount.where(
        depositor_id: @member.id, depositor_type: "Member"
      ).includes(:savings_product, :liability_account)
    end

    def time_deposits
      @time_deposits ||= Treasury::TimeDeposit.where(
        depositor_id: @member.id, depositor_type: "Member"
      ).includes(:time_deposit_product)
    end

    def loans
      @loans ||= Lending::Loan.where(member: @member).includes(:loan_product)
    end

    def share_capital_accounts
      @share_capital_accounts ||= Equity::Account.where(member: @member).includes(:share_product)
    end
  end
end
