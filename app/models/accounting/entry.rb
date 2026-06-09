module Accounting
  class Entry < ApplicationRecord
    self.table_name = "entries"

    has_many :amount_lines, dependent: :restrict_with_error

    has_many :debit_amount_lines, -> { where(amount_type: :debit) },
             class_name: "Accounting::AmountLine", inverse_of: :entry
    has_many :credit_amount_lines, -> { where(amount_type: :credit) },
             class_name: "Accounting::AmountLine", inverse_of: :entry
    has_many :debit_accounts, through: :debit_amount_lines, source: :account
    has_many :credit_accounts, through: :credit_amount_lines, source: :account

    validates :reference_number, presence: true, uniqueness: true
    validates :description, presence: true
    validates :posted_at, presence: true
    validate :validate_credit_amount_lines
    validate :validate_debit_amount_lines
    validate :amounts_cancel?

    scope :posted_on, ->(date) { where(posted_at: date.all_day) }
    scope :posted_between, ->(from, to) { where(posted_at: from..to) }

    def self.build(description:, reference_number: nil, posted_at: nil,
                   debits: [], credits: [])
      entry = new(
        description: description,
        reference_number: reference_number || generate_reference_number,
        posted_at: posted_at || Time.current
      )

      debits.each do |attrs|
        entry.debit_amount_lines.build(
          account: attrs[:account],
          amount_cents: attrs[:amount]
        )
      end

      credits.each do |attrs|
        entry.credit_amount_lines.build(
          account: attrs[:account],
          amount_cents: attrs[:amount]
        )
      end

      entry
    end

    private

    def validate_credit_amount_lines
      errors.add(:base, "must have at least one credit amount") if credit_amount_lines.blank?
    end

    def validate_debit_amount_lines
      errors.add(:base, "must have at least one debit amount") if debit_amount_lines.blank?
    end

    def amounts_cancel?
      debit_total = debit_amount_lines.sum(:amount_cents)
      credit_total = credit_amount_lines.sum(:amount_cents)
      if debit_total != credit_total
        errors.add(:base, "debits (#{debit_total}) do not equal credits (#{credit_total})")
      end
    end

    def self.generate_reference_number
      "ENT-#{Time.current.strftime("%Y%m%d-%H%M%S")}-#{SecureRandom.hex(4).upcase}"
    end
  end
end
