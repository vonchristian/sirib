module Accounting
  module AccountBalance
    class RunningBalance
      def initialize(to_date:, cooperative: nil, **)
        @to_date = to_date
        @cooperative = cooperative
      end

      def load_amounts
        scope = Accounting::RunningBalance.account_balances
        scope = scope.by_cooperative(@cooperative) if @cooperative
        scope.on_or_before(@to_date)
          .select("DISTINCT ON (account_id) account_id, balance_cents")
          .order(:account_id, as_of_date: :desc)
          .each_with_object({}) { |rb, h| h[rb.account_id] = rb.balance_cents }
      end
    end
  end
end
