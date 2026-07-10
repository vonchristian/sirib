module Accounting
  class AmountLine < ApplicationRecord
    self.table_name = "amount_lines"
    include CooperativeScoped

    belongs_to :entry, inverse_of: :amount_lines
    belongs_to :account, inverse_of: :amount_lines

    monetize :amount_cents

    enum :amount_type, { debit: 0, credit: 1 }

    validates :amount_type, presence: true
    validates :amount_cents, presence: true,
              numericality: { greater_than: 0 }

    scope :between, ->(from_date, to_date) {
      joins(:entry).merge(Entry.date_range(from_date, to_date))
    }

    scope :up_to, ->(date) {
      joins(:entry).merge(Entry.up_to(date))
    }

    scope :from_date, ->(date) {
      joins(:entry).merge(Entry.from_date(date))
    }

    def self.total
      sum(:amount_cents)
    end

    def self.balance(from_date: nil, to_date: nil, to_time: nil)
      AccountBalance.resolve(from_date: from_date, to_date: to_date, to_time: to_time)
        .apply(all)
        .sum(:amount_cents)
    end
  end
end
