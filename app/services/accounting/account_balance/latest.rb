module Accounting
  module AccountBalance
    class Latest
      def initialize(from_date: nil, to_date: nil, to_time: nil)
        @to_date = to_date || Date.current
      end

      def load_amounts
        AsOfDate.new(to_date: @to_date).load_amounts
      end

      def apply(scope)
        scope.up_to(@to_date)
      end
    end
  end
end
