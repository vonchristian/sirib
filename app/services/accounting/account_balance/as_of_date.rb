module Accounting
  module AccountBalance
    class AsOfDate
      def initialize(to_date:, **)
        @to_date = to_date
      end

      def load_amounts
        Accounting::AmountLine.joins(:entry)
          .where(entries: { posted_at: ..@to_date.end_of_day })
          .group(:account_id, :amount_type)
          .sum(:amount_cents)
      end

      def apply(scope)
        scope.up_to(@to_date)
      end
    end
  end
end
