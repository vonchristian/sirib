module Accounting
  class UpdateRunningBalances < ActiveInteraction::Base
    object :entry, class: Accounting::Entry

    def execute
      AppendOnlyOverride.with_override(reason: "RunningBalance batch update for entry #{entry.id}") do
        Accounting::RunningBalance.transaction do
          update_account_balances!
          update_ledger_balances!
        end
      end
    end

    private

    def update_account_balances!
      entry.accounts.distinct.each do |account|
        posted_date = entry.posted_at.to_date

        balance = Accounting::RunningBalance.find_or_initialize_by(
          account_id: account.id,
          as_of_date: posted_date
        )
        balance.ledger = account.ledger
        balance.balance_cents = account.balance(to_date: posted_date).cents
        balance.save!
      end
    end

    def update_ledger_balances!
      entry.accounts.includes(:ledger).distinct.map(&:ledger).uniq.each do |ledger|
        posted_date = entry.posted_at.to_date

        balance = Accounting::RunningBalance.find_or_initialize_by(
          ledger_id: ledger.id,
          account_id: nil,
          as_of_date: posted_date
        )
        balance.balance_cents = ledger.balance(to_date: posted_date)
        balance.save!
      end
    end
  end
end
