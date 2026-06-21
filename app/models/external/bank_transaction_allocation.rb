module External
  class BankTransactionAllocation < ApplicationRecord
    self.table_name = "external_bank_transaction_allocations"
    include CooperativeScoped

    belongs_to :bank_transaction, class_name: "External::BankTransaction", foreign_key: :external_bank_transaction_id
    belongs_to :journal_entry, class_name: "Accounting::Entry", foreign_key: :journal_entry_id, optional: true
    belongs_to :created_by, class_name: "User", foreign_key: :created_by_id, optional: true

    enum :status, { suggested: "suggested", confirmed: "confirmed", rejected: "rejected" }, default: :suggested

    validates :allocated_amount, presence: true
    validates :allocated_amount_cents, presence: true
    validates :status, presence: true

    scope :confirmed, -> { where(status: :confirmed) }
    scope :suggested, -> { where(status: :suggested) }
    scope :rejected, -> { where(status: :rejected) }

    def allocated_amount_money
      Money.new(allocated_amount_cents || 0, allocated_amount_currency)
    end

    def confirm!
      update!(status: :confirmed)
    end

    def reject!
      update!(status: :rejected)
    end

    def self.audit_message(action, allocation)
      {
        action: action,
        transaction_id: allocation.external_bank_transaction_id,
        journal_entry_id: allocation.journal_entry_id,
        amount_cents: allocation.allocated_amount_cents,
        status: allocation.status,
        user_id: allocation.created_by_id,
        timestamp: Time.current.utc.iso8601
      }
    end
  end
end