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
      post_line(
        type: :debit, amount: amount, cash_session: cash_session,
        description: description, idempotency_key: idempotency_key,
        from_account: from_account, to_account: to_account
      )
    end

    def credit(amount:, to_account:, cash_session:, from_account: nil, description: nil, idempotency_key: nil)
      post_line(
        type: :credit, amount: amount, cash_session: cash_session,
        description: description, idempotency_key: idempotency_key,
        from_account: from_account, to_account: to_account
      )
    end

    private

    def post_line(type:, amount:, cash_session:, description:, idempotency_key:, **extras)
      return Result.new(success?: false, errors: [ "Cash session must be open" ]) unless cash_session&.open?

      if type == :debit
        return Result.new(success?: false, errors: [ "Insufficient balance" ]) unless sufficient_balance?(extras[:from_account], amount)
      end

      description ||= "#{type.capitalize} transaction"
      entry = with_idempotency(key: idempotency_key) do
        ActiveRecord::Base.transaction do
          lock_accounts(extras[:from_account], extras[:to_account])

          ref_prefix = type == :debit ? "D" : "C"

          entry = Accounting::Entry.build(
            posted_at: Date.current.beginning_of_day,
            description: description,
            reference_number: "#{ref_prefix}-#{SecureRandom.uuid}",
            debits: [ { account: extras[:from_account] || extras[:to_account], amount: amount.cents } ],
            credits: [ { account: extras[:to_account], amount: amount.cents } ]
          )
          entry.save!
          entry
        end
      end

      result = build_transaction_from_entry(entry, amount, extras[:from_account], extras[:to_account], type.to_s, description, cash_session)
      Management::AuditLogService.run!(
        action: "#{type}_posted",
        auditable: entry,
        actor: Current.user,
        metadata: { type: type.to_s, amount: amount.to_s, description: description }
      )
      BroadcastService.transaction_posted(result)
      Result.new(success?: true, transaction: result)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, errors: [ e.message ])
    end

    def sufficient_balance?(account, amount)
      return false unless account

      account.balance >= amount
    end

    def lock_accounts(*accounts)
      ids = accounts.flatten.compact.map(&:id)
      Accounting::Account.lock("FOR UPDATE").where(id: ids).load if ids.any?
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
  end
end
