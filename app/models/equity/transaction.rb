module Equity
  class Transaction < ApplicationRecord
    self.table_name = "equity_transactions"

    TRANSACTION_TYPES = { purchase: 0, redemption: 1, transfer: 2, dividend: 3 }.freeze
    STATUSES = %w[completed reversed].freeze

    belongs_to :share_capital_account, class_name: "Equity::Account"
    belongs_to :cash_account, class_name: "Accounting::Account", optional: true
    belongs_to :entry, class_name: "Accounting::Entry", optional: true

    validates :transaction_type, presence: true
    validates :shares, presence: true, numericality: { greater_than: 0 }
    validates :price_per_share_cents, presence: true, numericality: { greater_than: 0 }
    validates :total_amount_cents, presence: true, numericality: { greater_than: 0 }
    validates :reference_number, presence: true, uniqueness: true
    validates :status, inclusion: { in: STATUSES }
    validates :posted_at, presence: true

    enum :transaction_type, TRANSACTION_TYPES

    scope :by_latest, -> { order(created_at: :desc) }
    scope :purchases, -> { where(transaction_type: :purchase) }

    before_validation :compute_total_amount, on: :create
    before_validation :assign_reference_number, on: :create
    before_validation :set_posted_at, on: :create

    def total_amount
      Money.new(total_amount_cents, "PHP")
    end

    def price_per_share
      Money.new(price_per_share_cents, "PHP")
    end

    private

    def compute_total_amount
      self.total_amount_cents ||= shares * price_per_share_cents
    end

    def assign_reference_number
      return if reference_number.present?
      prefix = "SCP"
      date_part = Time.current.strftime("%Y%m%d")
      random_part = SecureRandom.hex(3).upcase
      self.reference_number = "#{prefix}-#{date_part}-#{random_part}"
    end

    def set_posted_at
      self.posted_at ||= Time.current
    end
  end
end
