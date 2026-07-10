module Accounting
  module AccountBalance
    class AsOfDateTime
      def initialize(to_date:, to_time:, **)
        @to_date = to_date
        @to_time = to_time
      end

      def load_amounts
        Accounting::AmountLine.joins(:entry)
          .where(entries: { posted_at: ..cutoff })
          .group(:account_id, :amount_type)
          .sum(:amount_cents)
      end

      def apply(scope)
        scope.joins(:entry).merge(Accounting::Entry.up_to(cutoff))
      end

      private

      def cutoff
        @cutoff ||= @to_date.in_time_zone.change(
          hour: @to_time.hour,
          min: @to_time.min,
          sec: @to_time.sec
        )
      end
    end
  end
end
