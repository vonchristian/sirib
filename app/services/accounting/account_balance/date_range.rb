module Accounting
  module AccountBalance
    class DateRange
      def initialize(from_date:, to_date: nil, **)
        @from_date = from_date
        @to_date = to_date || Date.current
      end

      def load_amounts
        Accounting::AmountLine.joins(:entry)
          .where(entries: { posted_at: @from_date.beginning_of_day..@to_date.end_of_day })
          .group(:account_id, :amount_type)
          .sum(:amount_cents)
      end

      def apply(scope)
        scope.between(@from_date, @to_date)
      end
    end
  end
end
