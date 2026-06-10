module Accounting
  module AccountBalance
    class RunningBalance
      def initialize(to_date:, **)
        @to_date = to_date
      end

      def load_amounts
        Accounting::RunningBalance.account_balances
          .on_or_before(@to_date)
          .select("DISTINCT ON (account_id) account_id, balance_cents")
          .order(:account_id, as_of_date: :desc)
          .each_with_object({}) { |rb, h| h[rb.account_id] = rb.balance_cents }
      end
    end
  end
end
