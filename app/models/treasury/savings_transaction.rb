module Treasury
  class SavingsTransaction < ApplicationRecord
    self.table_name = "treasury_savings_transactions"

    TRANSACTION_TYPES = { deposit: 0, withdraw: 1 }.freeze
    STATUSES = %w[pending completed failed].freeze

    belongs_to :savings_account, class_name: "Treasury::SavingsAccount"
    belongs_to :cash_account, class_name: "Accounting::Account"
    belongs_to :entry, class_name: "Accounting::Entry", optional: true

    validates :transaction_type, presence: true
    validates :amount_cents, presence: true, numericality: { greater_than: 0 }
    validates :reference_number, presence: true, uniqueness: true
    validates :status, inclusion: { in: STATUSES }
    validates :posted_at, presence: true

    enum :transaction_type, TRANSACTION_TYPES

    scope :by_latest, -> { order(created_at: :desc) }

    before_validation :assign_reference_number, on: :create
    before_validation :set_posted_at, on: :create

    private

    def assign_reference_number
      return if reference_number.present?
      prefix = deposit? ? "SD" : "SW"
      date_part = Time.current.strftime("%Y%m%d")
      random_part = SecureRandom.hex(3).upcase
      self.reference_number = "#{prefix}-#{date_part}-#{random_part}"
    end

    def set_posted_at
      self.posted_at ||= Time.current
    end
  end
end
