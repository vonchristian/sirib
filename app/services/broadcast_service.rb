class BroadcastService
  def self.entry_posted(entry)
    Turbo::StreamsChannel.broadcast_replace_to(
      "shell_ledger",
      target: "ledger_entries",
      partial: "shell/ledger/entry",
      locals: { entry: entry }
    )
  end

  def self.transaction_posted(transaction)
    Turbo::StreamsChannel.broadcast_replace_to(
      "shell_transactions",
      target: "recent_transactions",
      partial: "shell/transactions/recent",
      locals: { transactions: [ transaction ] }
    )
  end
end
