module Members
  class SavingsSummaryService
    def initialize(member)
      @member = member
    end

    def call
      accounts = Treasury::SavingsAccount.where(
        depositor_id: @member.id, depositor_type: "Member"
      ).includes(:savings_product, :liability_account).by_latest

      {
        accounts: accounts,
        total_balance: accounts.sum { |a| a.balance.cents },
        active_count: accounts.active.count,
        total_count: accounts.count
      }
    end
  end
end
