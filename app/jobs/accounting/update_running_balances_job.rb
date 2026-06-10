module Accounting
  class UpdateRunningBalancesJob < ApplicationJob
    queue_as :default

    def perform(entry)
      Accounting::UpdateRunningBalances.run!(entry: entry)
      Turbo::StreamsChannel.broadcast_refresh_to "accounting_balances"
    end
  end
end
