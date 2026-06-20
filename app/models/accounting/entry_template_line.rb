module Accounting
  class EntryTemplateLine < ApplicationRecord
    self.table_name = "entry_template_lines"

    belongs_to :entry_template, class_name: "Accounting::EntryTemplate"
    belongs_to :account, class_name: "Accounting::Account"

    enum :direction, { debit: "debit", credit: "credit" }
    enum :amount_mode, { variable: "variable", fixed: "fixed" }, default: :variable

    validates :direction, presence: true
    validates :amount_mode, presence: true
    validates :fixed_amount, presence: true, if: :fixed?
    validates :sequence_index, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    scope :by_sequence, -> { order(sequence_index: :asc) }
    scope :debits, -> { where(direction: :debit) }
    scope :credits, -> { where(direction: :credit) }
    scope :variable, -> { where(amount_mode: :variable) }
    scope :fixed, -> { where(amount_mode: :fixed) }
  end
end
