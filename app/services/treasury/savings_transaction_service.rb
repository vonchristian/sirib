module Treasury
  class SavingsTransactionService < ActiveInteraction::Base
    object :savings_account, class: Treasury::SavingsAccount
    string :transaction_type
    integer :amount_cents
    string :amount_currency, default: "PHP"
    object :cash_account, class: Accounting::Account
    string :notes, default: nil

    validates :transaction_type, inclusion: { in: %w[deposit withdraw] }

    def execute
      errors.add(:amount_cents, "must be greater than zero") and return unless amount_cents.positive?

      if transaction_type == "withdraw" && amount_cents > savings_account.balance.cents
        errors.add(:base, "Insufficient balance") and return
      end

      savings_account.transaction do
        entry = post_journal_entry!

        transaction = Treasury::SavingsTransaction.create!(
          savings_account: savings_account,
          transaction_type: transaction_type,
          amount_cents: amount_cents,
          amount_currency: amount_currency,
          cash_account: cash_account,
          entry: entry,
          notes: notes,
          status: "completed",
          posted_at: Time.current
        )

        transaction
      end
    end

    private

    def post_journal_entry!
      liability = savings_account.liability_account
      unless liability
        errors.add(:base, "Savings account has no liability account assigned") and throw(:abort)
      end

      if transaction_type == "deposit"
        Accounting::PostEntryService.run!(
          description: "Savings deposit - #{savings_account.account_number}",
          reference_number: "SD-#{savings_account.account_number}",
          posted_at: Time.current,
          debits: [{ account: cash_account, amount: amount_cents }],
          credits: [{ account: liability, amount: amount_cents }]
        )
      else
        Accounting::PostEntryService.run!(
          description: "Savings withdrawal - #{savings_account.account_number}",
          reference_number: "SW-#{savings_account.account_number}",
          posted_at: Time.current,
          debits: [{ account: liability, amount: amount_cents }],
          credits: [{ account: cash_account, amount: amount_cents }]
        )
      end
    end
  end
end
