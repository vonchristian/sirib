module Accounting
  class Entry < ApplicationRecord
    include PgSearch::Model
    self.table_name = "entries"
    include CooperativeScoped

    pg_search_scope :search, against: [:description, :reference_number],
      using: { tsearch: { prefix: true, dictionary: "english" }, trigram: { threshold: 0.3 } }

    belongs_to :branch, class_name: "Management::Branch", foreign_key: :branch_id, optional: true
    belongs_to :created_by, class_name: "User", foreign_key: :created_by_id, optional: true
    belongs_to :template, class_name: "Accounting::EntryTemplate", foreign_key: :template_id, optional: true
    belongs_to :reversal_of, class_name: "Accounting::Entry", foreign_key: :reversal_of_id, optional: true
    has_one :reversed_entry, class_name: "Accounting::Entry", foreign_key: :reversal_of_id

    has_many :entry_templates, class_name: "Accounting::EntryTemplate", dependent: :nullify
    has_many :amount_lines, dependent: :restrict_with_error, autosave: true
    has_many :accounts, through: :amount_lines

    enum :status, { pending: "pending", posted: "posted", reversed: "reversed" }, default: :posted
    enum :entry_type, {
      manual_entry: "manual_entry",
      system_entry: "system_entry",
      interest_entry: "interest_entry",
      fees_entry: "fees_entry",
      reversal_entry: "reversal_entry",
      adjustment_entry: "adjustment_entry"
    }, default: :manual_entry
    enum :source_module, {
      source_loans: "source_loans",
      source_deposits: "source_deposits",
      source_external_banking: "source_external_banking",
      source_manual: "source_manual",
      source_treasury: "source_treasury",
      source_equity: "source_equity"
    }, default: :source_manual

    validates :reference_number, presence: true, uniqueness: { scope: :cooperative_id }
    validates :description, presence: true
    validates :posted_at, presence: true
    validates :status, presence: true
    validates :entry_type, presence: true
    validates :source_module, presence: true
    validate :validate_credit_amount_lines
    validate :validate_debit_amount_lines
    validate :amounts_cancel?
    validate :no_reversals_of_reversed_entries

    scope :posted_on, ->(date) { where(posted_at: date.all_day) }
    scope :up_to, ->(date) { where(posted_at: ..date.end_of_day) }
    scope :from_date, ->(date) { where(posted_at: date.beginning_of_day..) }
    scope :by_branch, ->(branch_id) { where(branch_id: branch_id) }
    scope :by_entry_type, ->(type) { where(entry_type: type) }
    scope :by_status, ->(status) { where(status: status) }
    scope :by_source_module, ->(module_name) { where(source_module: module_name) }
    scope :by_account, ->(account_id) { joins(:amount_lines).where(amount_lines: { account_id: account_id }).distinct }
    scope :by_created_by, ->(user_id) { where(created_by_id: user_id) }
    scope :has_attachments, -> { where(has_attachments: true) }
    scope :inter_branch, -> { where(inter_branch: true) }
    scope :pending, -> { where(status: :pending) }
    scope :posted, -> { where(status: :posted) }
    scope :reversed, -> { where(status: :reversed) }
    scope :date_range, ->(start_date, end_date) { where(posted_at: start_date.beginning_of_day..end_date.end_of_day) }

    def entry_date
      posted_at&.to_date
    end

    def entry_date=(date)
      self.posted_at = date.is_a?(Date) ? date.beginning_of_day : date
    end

    def total_debits
      amount_lines.select(&:debit?).sum(&:amount_cents)
    end

    def total_credits
      amount_lines.select(&:credit?).sum(&:amount_cents)
    end

    def net_amount
      total_debits - total_credits
    end

    def reversible?
      status == :posted && !reversed?
    end

    def reversed?
      status == :reversed || reversed_at.present?
    end

    def reverse!(reversed_by:, reason: nil)
      return false unless reversible?

      transaction do
        update!(
          status: :reversed,
          reversed_at: Time.current
        )
      end
      true
    end

    def self.build(description:, reference_number: nil, posted_at: nil,
                   debits: [], credits: [], cooperative: nil)
      entry = new(
        description: description,
        reference_number: reference_number || generate_reference_number,
        posted_at: posted_at || Time.current,
        cooperative: cooperative
      )

      debits.each do |attrs|
        entry.amount_lines.build(
          account: attrs[:account],
          amount_cents: attrs[:amount],
          amount_type: :debit,
          cooperative: cooperative
        )
      end

      credits.each do |attrs|
        entry.amount_lines.build(
          account: attrs[:account],
          amount_cents: attrs[:amount],
          amount_type: :credit,
          cooperative: cooperative
        )
      end

      entry
    end

    private

    def validate_credit_amount_lines
      errors.add(:base, "must have at least one credit amount") if amount_lines.select(&:credit?).blank?
    end

    def validate_debit_amount_lines
      errors.add(:base, "must have at least one debit amount") if amount_lines.select(&:debit?).blank?
    end

    def amounts_cancel?
      return if amount_lines.empty?

      debit_total = amount_lines.select(&:debit?).sum(&:amount_cents)
      credit_total = amount_lines.select(&:credit?).sum(&:amount_cents)
      if debit_total != credit_total
        errors.add(:base, "debits (#{debit_total}) do not equal credits (#{credit_total})")
      end
    end

    def no_reversals_of_reversed_entries
      return unless reversal_of_id.present?

      if reversal_of.reversed?
        errors.add(:base, "Cannot reverse an already reversed entry")
      end
    end

    def self.generate_reference_number
      "ENT-#{Time.current.strftime("%Y%m%d-%H%M%S")}-#{SecureRandom.hex(4).upcase}"
    end
  end
end