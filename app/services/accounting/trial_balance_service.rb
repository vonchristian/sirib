module Accounting
  class TrialBalanceService < ActiveInteraction::Base
    date :as_of, default: Date.current

    def execute
      Account.asset.balance(to_date: as_of) -
        (Account.liability.balance(to_date: as_of) +
         Account.equity.balance(to_date: as_of) +
         Account.revenue.balance(to_date: as_of) -
         Account.expense.balance(to_date: as_of))
    end
  end
end
