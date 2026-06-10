module Accounting
  module AccountBalance
    STRATEGIES = {
      %i[to_date to_time]         => AsOfDateTime,
      %i[to_date]                 => AsOfDate,
      %i[from_date]               => DateRange,
      %i[from_date to_date]       => DateRange,
      []                          => Latest
    }.freeze

    def self.resolve(from_date: nil, to_date: nil, to_time: nil)
      raise ArgumentError, "to_time requires to_date" if to_time && !to_date

      key = { from_date:, to_date:, to_time: }
              .select { |_, v| v }
              .keys
              .sort

      STRATEGIES.fetch(key).new(from_date:, to_date:, to_time:)
    end

    def self.balance(account, amounts)
      debits = amounts[[ account.id, "debit" ]] || 0
      credits = amounts[[ account.id, "credit" ]] || 0

      cents = if account.normal_credit_balance? ^ account.contra
                credits - debits
      else
                debits - credits
      end

      Money.new(cents, "PHP")
    end
  end
end
