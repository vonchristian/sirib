require "ostruct"

module Banking
  class TransactionService
    include IdempotentService

    Result = Struct.new(:success?, :transaction, :errors, keyword_init: true) do
      def valid? = success?
    end

    def self.debit(amount:, from_account:, to_account:, cash_session:, description: nil, idempotency_key: nil)
      new.debit(amount:, from_account:, to_account:, cash_session:, description:, idempotency_key:)
    end

    def self.credit(amount:, to_account:, cash_session:, from_account: nil, description: nil, idempotency_key: nil)
      new.credit(amount:, to_account:, cash_session:, from_account:, description:, idempotency_key:)
    end

    def initialize(audit_logger: nil)
      @audit_logger = audit_logger
    end

    def debit(amount:, from_account:, to_account:, cash_session:, description: nil, idempotency_key: nil)
      if idempotency_key
        cached = find_idempotent_result(idempotency_key, amount, from_account, to_account, "debit", description, cash_session)
        return cached if cached
      end

      return Result.new(success?: false, errors: [ "Cash session must be open" ]) unless cash_session&.open?
      return Result.new(success?: false, errors: [ "Insufficient balance" ]) unless sufficient_balance?(from_account, amount)

      transaction = nil
      entry = nil
      ActiveRecord::Base.transaction do
        entry = Accounting::Entry.build(
          posted_at: Date.current.beginning_of_day,
          description: description || "Debit transfer",
          reference_number: "D-#{SecureRandom.uuid}",
          debits: [ { account: from_account, amount: amount.cents } ],
          credits: [ { account: to_account, amount: amount.cents } ]
        )
        entry.save!

        transaction = build_transaction_from_entry(entry, amount, from_account, to_account, "debit", description, cash_session)

        record_audit(transaction)
        record_idempotency!(idempotency_key, entry) if idempotency_key
      end

      broadcast_transaction(transaction)
      Result.new(success?: true, transaction: transaction)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, errors: [ e.message ])
    end

    def credit(amount:, to_account:, cash_session:, from_account: nil, description: nil, idempotency_key: nil)
      if idempotency_key
        cached = find_idempotent_result(idempotency_key, amount, from_account, to_account, "credit", description, cash_session)
        return cached if cached
      end

      return Result.new(success?: false, errors: [ "Cash session must be open" ]) unless cash_session&.open?

      source = from_account
      transaction = nil
      entry = nil
      ActiveRecord::Base.transaction do
        entry = Accounting::Entry.build(
          posted_at: Date.current.beginning_of_day,
          description: description || "Credit transaction",
          reference_number: "C-#{SecureRandom.uuid}",
          debits: [ { account: source, amount: amount.cents } ],
          credits: [ { account: to_account, amount: amount.cents } ]
        )
        entry.save!

        transaction = build_transaction_from_entry(entry, amount, nil, to_account, "credit", description, cash_session)

        record_audit(transaction)
        record_idempotency!(idempotency_key, entry) if idempotency_key
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

    def find_idempotent_result(key, amount, from_account, to_account, type, description, cash_session)
      existing = IdempotencyKey.active.find_by(key: key, cooperative_id: Current.cooperative&.id)
      return nil unless existing&.resource

      Result.new(
        success?: true,
        transaction: build_transaction_from_entry(existing.resource, amount, from_account, to_account, type, description, cash_session)
      )
    end

    def build_transaction_from_entry(entry, amount, from_account, to_account, type, description, cash_session)
      OpenStruct.new(
        id: entry.id,
        entry: entry,
        amount: amount,
        from_account: from_account,
        to_account: to_account,
        type: type,
        description: description,
        cash_session_id: cash_session&.id,
        created_at: entry.created_at
      )
    end

    def record_idempotency!(key, resource)
      idem_key = IdempotencyKey.find_or_initialize_by(key: key, cooperative: Current.cooperative)
      idem_key.update!(
        service: self.class.name,
        resource: resource,
        expires_at: 24.hours.from_now
      )
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
