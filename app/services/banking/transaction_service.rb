module Banking
  class TransactionService
    Result = Struct.new(:success?, :transaction, :errors, keyword_init: true) do
      def valid? = success?
    end

    def self.debit(amount:, from_account:, to_account:, cash_session:, description: nil, idempotency_key: nil)
      new.debit(amount:, from_account:, to_account:, cash_session:, description:, idempotency_key:)
    end

    def self.credit(amount:, to_account:, cash_session:, description: nil, idempotency_key: nil)
      new.credit(amount:, to_account:, cash_session:, description:, idempotency_key:)
    end

    def initialize(audit_logger: nil)
      @audit_logger = audit_logger
    end

    def debit(amount:, from_account:, to_account:, cash_session:, description: nil, idempotency_key: nil)
      return Result.new(success?: false, errors: [ "Cash session must be open" ]) unless cash_session&.open?
      return Result.new(success?: false, errors: [ "Insufficient balance" ]) unless sufficient_balance?(from_account, amount)

      validate_idempotency!(idempotency_key) if idempotency_key

      transaction = nil
      ActiveRecord::Base.transaction do
        entry = Accounting::Entry.create!(
          date: Date.current,
          description: description || "Debit transfer",
          entries_type: "banking"
        )

        entry.amount_lines.create!(
          account: from_account,
          amount_cents: -amount.cents,
          amount_currency: amount.currency.to_s,
          side: "debit"
        )

        entry.amount_lines.create!(
          account: to_account,
          amount_cents: amount.cents,
          amount_currency: amount.currency.to_s,
          side: "credit"
        )

        transaction = OpenStruct.new(
          id: SecureRandom.uuid,
          entry: entry,
          amount: amount,
          from_account: from_account,
          to_account: to_account,
          type: "debit",
          description: description,
          cash_session_id: cash_session.id,
          created_at: Time.current
        )

        record_audit(transaction)
      end

      broadcast_transaction(transaction)
      Result.new(success?: true, transaction: transaction)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, errors: [ e.message ])
    end

    def credit(amount:, to_account:, cash_session:, description: nil, idempotency_key: nil)
      return Result.new(success?: false, errors: [ "Cash session must be open" ]) unless cash_session&.open?

      validate_idempotency!(idempotency_key) if idempotency_key

      transaction = nil
      ActiveRecord::Base.transaction do
        entry = Accounting::Entry.create!(
          date: Date.current,
          description: description || "Credit transaction",
          entries_type: "banking"
        )

        entry.amount_lines.create!(
          account: to_account,
          amount_cents: amount.cents,
          amount_currency: amount.currency.to_s,
          side: "credit"
        )

        transaction = OpenStruct.new(
          id: SecureRandom.uuid,
          entry: entry,
          amount: amount,
          to_account: to_account,
          type: "credit",
          description: description,
          cash_session_id: cash_session.id,
          created_at: Time.current
        )

        record_audit(transaction)
      end

      broadcast_transaction(transaction)
      Result.new(success?: true, transaction: transaction)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, errors: [ e.message ])
    end

    private

    def sufficient_balance?(account, amount)
      account.balance >= amount
    end

    def validate_idempotency!(key)
      # In production, check against a idempotency table
      # raise ActiveRecord::RecordInvalid if key already processed
    end

    def record_audit(transaction)
      return unless defined?(Management::AuditLogService)

      Management::AuditLogService.log(
        action: "transaction_created",
        auditable: transaction,
        user: Current.user,
        details: {
          type: transaction.type,
          amount: transaction.amount.to_s,
          description: transaction.description
        }
      )
    rescue StandardError => e
      Rails.logger.warn("Audit log failed: #{e.message}")
    end

    def broadcast_transaction(transaction)
      Turbo::StreamsChannel.broadcast_replace_to(
        "shell_transactions",
        target: "recent_transactions",
        partial: "shell/transactions/recent",
        locals: { transactions: [ transaction ] }
      )
    rescue StandardError
      nil
    end
  end
end
