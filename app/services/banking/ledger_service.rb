module Banking
  class LedgerService
    Result = Struct.new(:success?, :entry, :errors, keyword_init: true) do
      def valid? = success?
    end

    def self.post_entry(description:, lines:, date: Date.current)
      new.post_entry(description:, lines:, date:)
    end

    def self.account_balance(account_id, as_of: Time.current)
      new.account_balance(account_id, as_of:)
    end

    def initialize
      @immutable = true
    end

    def post_entry(description:, lines:, date: Date.current)
      entry = nil
      ActiveRecord::Base.transaction do
        entry = Accounting::Entry.create!(
          date: date,
          description: description,
          entries_type: "ledger"
        )

        lines.each do |line|
          entry.amount_lines.create!(
            account: line[:account],
            amount_cents: line[:amount_cents],
            amount_currency: line[:amount_currency] || "PHP",
            side: line[:side]
          )
        end

        validate_balanced!(entry)
        entry.update!(status: "posted")
        record_audit(entry, lines)
      end

      broadcast_entry(entry)
      Result.new(success?: true, entry: entry)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, errors: [ e.message ])
    end

    def account_balance(account_id, as_of: Time.current)
      account = Accounting::Account.find(account_id)
      balance = Accounting::AccountBalance::AsOfDateTime.new(account, as_of).call
      { account: account.name, balance: balance, as_of: as_of }
    rescue StandardError => e
      Result.new(success?: false, errors: [ e.message ])
    end

    private

    def validate_balanced!(entry)
      total_debits = entry.amount_lines.where(side: "debit").sum(:amount_cents)
      total_credits = entry.amount_lines.where(side: "credit").sum(:amount_cents)

      unless total_debits == total_credits
        raise ActiveRecord::RecordInvalid.new(entry),
              "Unbalanced entry: debits (#{total_debits}) != credits (#{total_credits})"
      end
    end

    def record_audit(entry, lines)
      return unless defined?(Management::AuditLogService)

      Management::AuditLogService.log(
        action: "ledger_entry_posted",
        auditable: entry,
        user: Current.user,
        details: {
          description: entry.description,
          line_count: lines.size,
          total: lines.sum { |l| l[:amount_cents] }
        }
      )
    rescue StandardError => e
      Rails.logger.warn("Audit log failed: #{e.message}")
    end

    def broadcast_entry(entry)
      Turbo::StreamsChannel.broadcast_replace_to(
        "shell_ledger",
        target: "ledger_entries",
        partial: "shell/ledger/entry",
        locals: { entry: entry }
      )
    rescue StandardError
      nil
    end
  end
end
