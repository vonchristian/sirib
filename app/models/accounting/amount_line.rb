module Accounting
  class AmountLine < ApplicationRecord
    self.table_name = "amount_lines"

    belongs_to :entry, inverse_of: :amount_lines
    belongs_to :account, inverse_of: :amount_lines

    monetize :amount_cents

    enum :amount_type, { debit: 0, credit: 1 }

    validates :amount_type, presence: true
    validates :amount_cents, presence: true,
              numericality: { greater_than: 0 }
  end
end
