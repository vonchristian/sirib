module Accounting
  class PostPendingEntryService < ActiveInteraction::Base
    object :entry, class: Accounting::Entry

    def execute
      errors.add(:entry, "must be pending") and return unless entry.pending?

      Accounting::Entry.transaction do
        entry.update!(status: :posted)
        AppendOnlyOverride.with_override(reason: "RunningBalance update via PostPendingEntryService") do
          update_running_balances!(entry)
        end
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
        balance.cooperative = entry.cooperative
        balance.balance_cents = account.balance(to_date: posted_date).cents
        balance.save!
      end

      entry.accounts.includes(:ledger).distinct.map(&:ledger).uniq.each do |ledger|
        balance = Accounting::RunningBalance.find_or_initialize_by(
          ledger_id: ledger.id,
          account_id: nil,
          as_of_date: posted_date
        )
        balance.cooperative = entry.cooperative
        balance.balance_cents = ledger.balance(to_date: posted_date)
        balance.save!
      end
    end
  end
end
