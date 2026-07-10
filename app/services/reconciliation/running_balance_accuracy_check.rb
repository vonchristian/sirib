module Reconciliation
  class RunningBalanceAccuracyCheck < BaseCheck
    private

    def run_check
      failures = []
      account_scope = cooperative ? Accounting::Account.where(cooperative: cooperative) : Accounting::Account

      account_scope.find_each(batch_size: 100) do |account|
        computed = account.balance(to_date: as_of_date)
        stored = account.running_balances.where(as_of_date: as_of_date).last
        if stored && stored.balance_cents != computed.cents
          failures << {
            resource_type: "Accounting::Account",
            resource_id: account.id,
            account_code: account.account_code,
            expected: computed.cents,
            actual: stored.balance_cents,
            diff: stored.balance_cents - computed.cents,
            as_of_date: as_of_date
          }
        end
      end
      failures
    end

    def total_count
      scope = cooperative ? Accounting::Account.where(cooperative: cooperative) : Accounting::Account
      scope.count
    end
  end
end
