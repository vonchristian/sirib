module Accounting
  module AccountBalance
    def self.load_amounts(from_date: nil, to_date: nil, to_time: nil)
      if to_time && to_date
        cutoff = to_date.in_time_zone.change(hour: to_time.hour, min: to_time.min, sec: to_time.sec)
        Accounting::AmountLine.joins(:entry)
          .where(entries: { posted_at: ..cutoff })
          .group(:account_id, :amount_type)
          .sum(:amount_cents)
      elsif to_date && from_date
        Accounting::AmountLine.joins(:entry)
          .where(entries: { posted_at: from_date.beginning_of_day..to_date.end_of_day })
          .group(:account_id, :amount_type)
          .sum(:amount_cents)
      elsif to_date
        Accounting::AmountLine.joins(:entry)
          .where(entries: { posted_at: ..to_date.end_of_day })
          .group(:account_id, :amount_type)
          .sum(:amount_cents)
      else
        Accounting::AmountLine.joins(:entry)
          .where(entries: { posted_at: ..Date.current.end_of_day })
          .group(:account_id, :amount_type)
          .sum(:amount_cents)
      end
    end

    def self.apply_scope(scope, from_date: nil, to_date: nil, to_time: nil)
      if to_time && to_date
        cutoff = to_date.in_time_zone.change(hour: to_time.hour, min: to_time.min, sec: to_time.sec)
        scope.joins(:entry).merge(Accounting::Entry.up_to(cutoff))
      elsif from_date && to_date
        scope.between(from_date, to_date)
      elsif from_date
        scope.between(from_date, Date.current)
      else
        scope.up_to(to_date || Date.current)
      end
    end

    def self.load_running_balances(to_date:, cooperative: nil)
      scope = Accounting::RunningBalance.account_balances
      scope = scope.by_cooperative(cooperative) if cooperative
      scope.on_or_before(to_date)
        .select("DISTINCT ON (account_id) account_id, balance_cents")
        .order(:account_id, as_of_date: :desc)
        .each_with_object({}) { |rb, h| h[rb.account_id] = rb.balance_cents }
    end

    def self.balance(account, amounts)
      Money.new(amounts[account.id] || 0, "PHP")
    end
  end
end
