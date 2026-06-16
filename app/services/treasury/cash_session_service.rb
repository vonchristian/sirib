module Treasury
  class CashSessionService
    Result = Struct.new(:success?, :voucher, :transaction, :errors, keyword_init: true) do
      def valid? = success?
    end

    def self.deposit(cash_session:, savings_account:, amount:, cash_account:, notes: nil)
      new.deposit(cash_session:, savings_account:, amount:, cash_account:, notes:)
    end

    def self.withdraw(cash_session:, savings_account:, amount:, cash_account:, notes: nil)
      new.withdraw(cash_session:, savings_account:, amount:, cash_account:, notes:)
    end

    def deposit(cash_session:, savings_account:, amount:, cash_account:, notes: nil)
      voucher = cash_session.vouchers.new(
        type: "Treasury::CashReceiptVoucher",
        cash_account: cash_account,
        amount_cents: amount.cents,
        amount_currency: amount.currency.to_s,
        category: "savings_deposit",
        description: "Savings deposit — #{savings_account.account_number}",
        counterparty: savings_account.depositor
      )

      unless voucher.valid?
        return Result.new(success?: false, voucher: voucher, errors: voucher.errors.full_messages)
      end

      txn = nil
      ActiveRecord::Base.transaction do
        voucher.save!
        voucher.post_entry!(credit_account: savings_account.liability_account)

        txn = savings_account.transactions.create!(
          transaction_type: :deposit,
          amount_cents: amount.cents,
          amount_currency: amount.currency.to_s,
          cash_account: cash_account,
          entry: voucher.entry,
          notes: notes,
          status: "completed",
          posted_at: Time.current
        )

        voucher.update!(transactable: txn)
      end

      Result.new(success?: true, voucher: voucher, transaction: txn)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Result.new(success?: false, errors: [e.message])
    end

    def withdraw(cash_session:, savings_account:, amount:, cash_account:, notes: nil)
      voucher = cash_session.vouchers.new(
        type: "Treasury::CashDisbursementVoucher",
        cash_account: cash_account,
        amount_cents: amount.cents,
        amount_currency: amount.currency.to_s,
        category: "savings_withdrawal",
        description: "Savings withdrawal — #{savings_account.account_number}",
        counterparty: savings_account.depositor
      )

      unless voucher.valid?
        return Result.new(success?: false, voucher: voucher, errors: voucher.errors.full_messages)
      end

      txn = nil
      ActiveRecord::Base.transaction do
        voucher.save!
        voucher.post_entry!(debit_account: savings_account.liability_account)

        txn = savings_account.transactions.create!(
          transaction_type: :withdraw,
          amount_cents: amount.cents,
          amount_currency: amount.currency.to_s,
          cash_account: cash_account,
          entry: voucher.entry,
          notes: notes,
          status: "completed",
          posted_at: Time.current
        )

        voucher.update!(transactable: txn)
      end

      Result.new(success?: true, voucher: voucher, transaction: txn)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Result.new(success?: false, errors: [e.message])
    end
  end
end
