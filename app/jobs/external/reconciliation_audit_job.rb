module External
  class ReconciliationAuditJob < ApplicationJob
    queue_as :default

    def perform(allocation, action, user_id)
      Rails.logger.info "ReconciliationAudit: #{action} allocation ##{allocation.id} " \
                        "(tx: #{allocation.external_bank_transaction_id}, " \
                        "entry: #{allocation.journal_entry_id}, " \
                        "amount: #{allocation.allocated_amount_cents}, " \
                        "user: #{user_id})"
    end
  end
end