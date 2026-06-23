class RecomputeRunningBalances < ActiveRecord::Migration[8.0]
  def up
    say "Recomputing running balances for all accounts..."

    # Delete all existing account-level running balances
    Accounting::RunningBalance.account_balances.delete_all

    # For each account, get all its amount lines and compute balance at each entry date
    Accounting::Account.find_each do |account|
      say "  Processing account #{account.account_code}..."

      # Get all distinct entry dates for this account's amount lines
      entry_dates = Accounting::AmountLine
        .joins(:entry)
        .where(account_id: account.id)
        .where.not(entries: { posted_at: nil })
        .pluck(Arel.sql("DISTINCT DATE(entries.posted_at)"))
        .sort

      entry_dates.each do |date|
        balance = account.balance(to_date: date)

        Accounting::RunningBalance.create!(
          account_id: account.id,
          ledger_id: account.ledger_id,
          as_of_date: date,
          cooperative_id: account.cooperative_id,
          balance_cents: balance.cents,
          balance_currency: "PHP"
        )
      end
    end

    say "Done recomputing #{Accounting::RunningBalance.account_balances.count} account running balances."
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end