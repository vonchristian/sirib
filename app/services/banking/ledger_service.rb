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
        entry = Accounting::Entry.new(
          posted_at: date.beginning_of_day,
          description: description,
          reference_number: "LEDGER-#{SecureRandom.uuid}",
          entry_type: "system_entry",
          source_module: "source_manual",
          status: "pending"
        )

        lines.each do |line|
          entry.amount_lines.build(
            account: line[:account],
            amount_cents: line[:amount_cents],
            amount_currency: line[:amount_currency] || "PHP",
            amount_type: line[:amount_type]
          )
        end

        Accounting::ValidationEngine.validate!(entry)
        entry.save!
        entry.update!(status: "posted")
      end

      Management::AuditLogService.run!(
        action: "ledger_entry_posted",
        auditable: entry,
        actor: Current.user,
        metadata: {
          description: entry.description,
          line_count: lines.size,
          total: lines.sum { |l| l[:amount_cents] }
        }
      )
      BroadcastService.entry_posted(entry)
      Result.new(success?: true, entry: entry)
    rescue ActiveRecord::RecordInvalid, Accounting::ValidationEngine::ValidationError => e
      Result.new(success?: false, errors: [ e.message ])
    end

    def account_balance(account_id, as_of: Time.current)
      account = Accounting::Account.find(account_id)
      strategy = Accounting::AccountBalance.resolve(to_date: as_of.to_date, to_time: as_of)
      amounts = strategy.load_amounts
      balance = Accounting::AccountBalance.balance(account, amounts)
      { account: account.name, balance: balance, as_of: as_of }
    rescue StandardError => e
      # Intentionally broad: query methods return errors in Result struct
      # rather than propagating exceptions — caller chooses how to handle.
      Result.new(success?: false, errors: [ e.message ])
    end
  end
end
