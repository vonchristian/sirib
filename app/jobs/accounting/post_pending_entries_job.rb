module Accounting
  class PostPendingEntriesJob < ApplicationJob
    queue_as :default

    def perform
      Accounting::Entry.pending.where("posted_at <= ?", Time.current).find_each do |entry|
        Accounting::PostPendingEntryService.run!(entry: entry)
      rescue => e
        Rails.logger.error("Failed to post pending entry #{entry.id}: #{e.message}")
      end
    end
  end
end
