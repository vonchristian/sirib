module Accounting
  class PostEntryService < ActiveInteraction::Base
    string :description
    string :reference_number, default: nil
    time :posted_at, default: nil
    object :cooperative, class: Cooperative, default: nil
    array :debits, default: [] do
      hash do
        object :account, class: Accounting::Account
        integer :amount
      end
    end
    array :credits, default: [] do
      hash do
        object :account, class: Accounting::Account
        integer :amount
      end
    end

    def execute
      entry = Accounting::Entry.build(
        description: description,
        reference_number: reference_number,
        posted_at: posted_at,
        debits: debits,
        credits: credits,
        cooperative: cooperative
      )

      Accounting::Entry.transaction do
        entry.save!
        update_running_balances!(entry)
      end

      entry
    end

    private

    def update_running_balances!(entry)
      posted_date = entry.posted_at.to_date

      entry.accounts.distinct.each do |account|
        balance = Accounting::RunningBalance.find_or_initialize_by(
          account_id: account.id,
          as_of_date: posted_date
        )
        balance.ledger = account.ledger
        balance.cooperative = cooperative if cooperative
        balance.balance_cents = account.balance(to_date: posted_date).cents
        balance.save!
      end

      entry.accounts.includes(:ledger).distinct.map(&:ledger).uniq.each do |ledger|
        balance = Accounting::RunningBalance.find_or_initialize_by(
          ledger_id: ledger.id,
          account_id: nil,
          as_of_date: posted_date
        )
        balance.cooperative = cooperative if cooperative
        balance.balance_cents = ledger.balance(to_date: posted_date)
        balance.save!
      end
    end
  end
end
