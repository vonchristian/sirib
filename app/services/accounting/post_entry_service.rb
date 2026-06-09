module Accounting
  class PostEntryService
    def self.call(...)
      new(...).call
    end

    def initialize(description:, reference_number: nil, posted_at: nil,
                   debits: [], credits: [])
      @description = description
      @reference_number = reference_number
      @posted_at = posted_at
      @debits = debits
      @credits = credits
    end

    def call
      entry = Accounting::Entry.build(
        description: @description,
        reference_number: @reference_number,
        posted_at: @posted_at,
        debits: @debits,
        credits: @credits
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

      entry.amount_lines.group_by(&:account_id).each do |account_id, lines|
        account = lines.first.account
        net_change = account.normal_credit_balance? ^ account.contra ?
          lines.sum { |l| l.credit? ? l.amount_cents : -l.amount_cents } :
          lines.sum { |l| l.debit? ? l.amount_cents : -l.amount_cents }

        previous = Accounting::RunningBalance.latest_for_account(account_id, date: posted_date)
        new_balance = (previous&.balance_cents || 0) + net_change

        balance = Accounting::RunningBalance.find_or_initialize_by(
          account_id: account_id,
          as_of_date: posted_date
        )
        balance.ledger = account.ledger
        balance.balance_cents = new_balance
        balance.save!
      end

      entry.amount_lines.map { |l| l.account.ledger }.uniq.each do |ledger|
        lines = entry.amount_lines.select { |l| l.account.ledger_id == ledger.id }
        ledger_net_change = lines.sum { |l| l.debit? ? l.amount_cents : -l.amount_cents }

        previous = Accounting::RunningBalance.latest_for_ledger(ledger.id, date: posted_date)
        new_balance = (previous&.balance_cents || 0) + ledger_net_change

        balance = Accounting::RunningBalance.find_or_initialize_by(
          ledger_id: ledger.id,
          account_id: nil,
          as_of_date: posted_date
        )
        balance.balance_cents = new_balance
        balance.save!
      end
    end
  end
end
