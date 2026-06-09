module Accounting
  class RebuildRunningBalancesService
    def self.call
      new.call
    end

    def call
      Accounting::RunningBalance.delete_all

      account_balances = Hash.new(0)
      ledger_balances = Hash.new(0)

      Accounting::Entry.order(posted_at: :asc).find_each do |entry|
        posted_date = entry.posted_at.to_date

        entry.amount_lines.group_by(&:account_id).each do |account_id, lines|
          account = lines.first.account
          net_change = account.normal_credit_balance? ^ account.contra ?
            lines.sum { |l| l.credit? ? l.amount_cents : -l.amount_cents } :
            lines.sum { |l| l.debit? ? l.amount_cents : -l.amount_cents }

          account_balances[account_id] += net_change

          balance = Accounting::RunningBalance.find_or_initialize_by(
            account_id: account_id,
            as_of_date: posted_date
          )
          balance.ledger = account.ledger
          balance.balance_cents = account_balances[account_id]
          balance.save!
        end

        entry.amount_lines.map { |l| l.account.ledger_id }.uniq.each do |ledger_id|
          lines = entry.amount_lines.select { |l| l.account.ledger_id == ledger_id }
          ledger_net_change = lines.sum { |l| l.debit? ? l.amount_cents : -l.amount_cents }

          ledger_balances[ledger_id] += ledger_net_change

          balance = Accounting::RunningBalance.find_or_initialize_by(
            ledger_id: ledger_id,
            account_id: nil,
            as_of_date: posted_date
          )
          balance.balance_cents = ledger_balances[ledger_id]
          balance.save!
        end
      end
    end
  end
end
