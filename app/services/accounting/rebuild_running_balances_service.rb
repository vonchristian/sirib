module Accounting
  class RebuildRunningBalancesService < ActiveInteraction::Base
    def execute
      Accounting::RunningBalance.delete_all

      Accounting::Entry.order(posted_at: :asc).find_each do |entry|
        posted_date = entry.posted_at.to_date

        entry.accounts.distinct.each do |account|
          balance = Accounting::RunningBalance.find_or_initialize_by(
            account_id: account.id,
            as_of_date: posted_date
          )
          balance.ledger = account.ledger
          balance.balance_cents = account.balance(to_date: posted_date).cents
          balance.save!
        end

        entry.accounts.includes(:ledger).distinct.map(&:ledger).uniq.each do |ledger|
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
end
