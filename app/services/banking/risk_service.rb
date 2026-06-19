module Banking
  class RiskService
    Result = Struct.new(:safe?, :flags, :score, keyword_init: true) do
      def valid? = safe?
    end

    FLAGS = {
      large_amount: { threshold: 100_000, label: "Large Amount", severity: "medium" },
      overdraft_risk: { label: "Overdraft Risk", severity: "high" },
      unusual_frequency: { threshold: 10, window: 1.hour, label: "Unusual Frequency", severity: "medium" },
      duplicate_transaction: { label: "Duplicate Transaction", severity: "high" }
    }.freeze

    def self.evaluate(transaction: nil, account: nil, user: nil)
      new.evaluate(transaction:, account:, user:)
    end

    def evaluate(transaction: nil, account: nil, user: nil)
      flags = []
      flags << check_large_amount(transaction) if transaction
      flags << check_overdraft(account, transaction) if account && transaction
      flags << check_frequency(account, user) if account
      flags.compact!

      score = compute_score(flags)
      safe = flags.empty?

      Result.new(safe?: safe, flags: flags, score: score)
    end

    private

    def check_large_amount(transaction)
      return nil unless transaction.amount_cents > FLAGS[:large_amount][:threshold]

      {
        type: "large_amount",
        label: FLAGS[:large_amount][:label],
        severity: FLAGS[:large_amount][:severity],
        detail: "Transaction amount (#{format_amount(transaction.amount_cents)}) exceeds #{format_amount(FLAGS[:large_amount][:threshold])} threshold"
      }
    end

    def check_overdraft(account, transaction)
      return nil unless transaction.amount_cents.present? && transaction.amount_cents > 0

      current_balance = account.balance.cents
      if current_balance - transaction.amount_cents < 0
        {
          type: "overdraft_risk",
          label: FLAGS[:overdraft_risk][:label],
          severity: FLAGS[:overdraft_risk][:severity],
          detail: "Transaction would overdraw account. Balance: #{format_amount(current_balance)}, Required: #{format_amount(transaction.amount_cents)}"
        }
      end
    end

    def check_frequency(account, user)
      return nil unless account && user

      recent_count = Accounting::Entry
        .joins(:amount_lines)
        .where(amount_lines: { account_id: account.id })
        .where("entries.created_at > ?", FLAGS[:unusual_frequency][:window].ago)
        .count

      if recent_count >= FLAGS[:unusual_frequency][:threshold]
        {
          type: "unusual_frequency",
          label: FLAGS[:unusual_frequency][:label],
          severity: FLAGS[:unusual_frequency][:severity],
          detail: "#{recent_count} transactions on this account in the last hour"
        }
      end
    end

    def compute_score(flags)
      return 0 if flags.empty?

      weights = { "low" => 1, "medium" => 3, "high" => 5 }
      total = flags.sum { |f| weights.fetch(f[:severity], 1) }
      [ total, 10 ].min
    end

    def format_amount(cents)
      format("₱%.2f", cents.to_f / 100)
    end
  end
end
