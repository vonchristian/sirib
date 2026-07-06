module External
  class BankTransaction < ApplicationRecord
    self.table_name = "external_bank_transactions"
    include CooperativeScoped

    belongs_to :account, class_name: "External::BankAccount", foreign_key: :external_bank_account_id
    belongs_to :document, class_name: "External::BankDocument", foreign_key: :external_bank_document_id, optional: true

    has_many :allocations, class_name: "External::BankTransactionAllocation", foreign_key: :external_bank_transaction_id, dependent: :destroy

    enum :direction, { debit: "debit", credit: "credit" }

    validates :transaction_date, presence: true
    validates :amount_cents, presence: true
    validates :direction, presence: true
    validates :hash_signature, presence: true, uniqueness: true

    scope :for_account, ->(account_id) { where(external_bank_account_id: account_id) }
    scope :unreconciled, -> { left_outer_joins(:allocations).where(external_bank_transaction_allocations: { id: nil }) }
    scope :by_date, -> { order(transaction_date: :asc) }
    scope :by_date_desc, -> { order(transaction_date: :desc) }

    delegate :bank_name, to: :account, allow_nil: true
    delegate :currency, to: :account, allow_nil: true

    def amount_money
      Money.new(amount_cents || 0, amount_currency)
    end

    def running_balance_money
      return nil unless running_balance_cents

      Money.new(running_balance_cents, running_balance_currency)
    end

    def reconciled_amount
      allocations.where(status: :confirmed).sum(:allocated_amount_cents)
    end

    def reconciled?
      allocations.where(status: :confirmed).exists?
    end

    def suggested_amount
      allocations.where(status: :suggested).sum(:allocated_amount_cents)
    end

    def allocate_to_entry!(journal_entry, amount_cents:, status: :suggested, confidence_score: nil, user: nil)
      allocations.create!(
        journal_entry_id: journal_entry.id,
        allocated_amount_cents: amount_cents,
        allocated_amount: amount_cents.to_d / 100,
        allocated_amount_currency: amount_currency,
        status: status,
        confidence_score: confidence_score,
        created_by: user
      )
    end

    def self.generate_hash_signature(account_id:, transaction_date:, description:, amount:, direction:, reference_number: nil)
      data = [
        account_id,
        transaction_date.iso8601,
        description.to_s.squish,
        amount.to_s,
        direction.to_s,
        reference_number.to_s
      ].join("|")

      Digest::SHA256.hexdigest(data)
    end
  end
end
