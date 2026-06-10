module Accounting
  class Entry < ApplicationRecord
    include PgSearch::Model
    self.table_name = "entries"

    pg_search_scope :search, against: [:description, :reference_number],
      using: { tsearch: { prefix: true, dictionary: "english" }, trigram: { threshold: 0.3 } }

    has_many :amount_lines, dependent: :restrict_with_error
    has_many :accounts, through: :amount_lines

    validates :reference_number, presence: true, uniqueness: true
    validates :description, presence: true
    validates :posted_at, presence: true
    validate :validate_credit_amount_lines
    validate :validate_debit_amount_lines
    validate :amounts_cancel?

    scope :posted_on, ->(date) { where(posted_at: date.all_day) }
    scope :up_to, ->(date) { where(posted_at: ..date.end_of_day) }
    scope :from_date, ->(date) { where(posted_at: date.beginning_of_day..) }

    def self.build(description:, reference_number: nil, posted_at: nil,
                   debits: [], credits: [])
      entry = new(
        description: description,
        reference_number: reference_number || generate_reference_number,
        posted_at: posted_at || Time.current
      )

      debits.each do |attrs|
        entry.amount_lines.build(
          account: attrs[:account],
          amount_cents: attrs[:amount],
          amount_type: :debit
        )
      end

      credits.each do |attrs|
        entry.amount_lines.build(
          account: attrs[:account],
          amount_cents: attrs[:amount],
          amount_type: :credit
        )
      end

      entry
    end

    private

    def validate_credit_amount_lines
      errors.add(:base, "must have at least one credit amount") if amount_lines.credit.blank?
    end

    def validate_debit_amount_lines
      errors.add(:base, "must have at least one debit amount") if amount_lines.debit.blank?
    end

    def amounts_cancel?
      debit_total = amount_lines.debit.total
      credit_total = amount_lines.credit.total
      if debit_total != credit_total
        errors.add(:base, "debits (#{debit_total}) do not equal credits (#{credit_total})")
      end
    end

    def self.generate_reference_number
      "ENT-#{Time.current.strftime("%Y%m%d-%H%M%S")}-#{SecureRandom.hex(4).upcase}"
    end
  end
end
