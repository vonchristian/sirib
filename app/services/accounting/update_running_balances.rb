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
      locked_accounts.each do |account|
        posted_date = entry.posted_at.to_date
        balance_cents = account.balance(to_date: posted_date).cents

        rb = Accounting::RunningBalance
          .lock("FOR UPDATE")
          .find_or_initialize_by(account_id: account.id, as_of_date: posted_date)

        rb.update!(
          balance_cents: balance_cents,
          ledger: account.ledger
        )
      end
    end

    def update_ledger_balances!
      locked_ledgers.each do |ledger|
        posted_date = entry.posted_at.to_date
        balance_cents = ledger.balance(to_date: posted_date)

        rb = Accounting::RunningBalance
          .lock("FOR UPDATE")
          .find_or_initialize_by(ledger_id: ledger.id, account_id: nil, as_of_date: posted_date)

        rb.update!(balance_cents: balance_cents)
      end
    end

    def locked_accounts
      Accounting::Account
        .lock("FOR UPDATE")
        .where(id: entry.accounts.select(:id))
    end

    def locked_ledgers
      ledger_ids = entry.accounts.includes(:ledger).distinct.map(&:ledger_id).uniq
      Accounting::Ledger
        .lock("FOR UPDATE")
        .where(id: ledger_ids)
    end
  end
end
