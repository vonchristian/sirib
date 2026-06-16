module Treasury
  class TimeDepositProduct < ApplicationRecord
    self.table_name = "treasury_time_deposit_products"

    monetize :minimum_deposit_cents

    STATUSES = %w[active inactive].freeze

    validates :name, presence: true
    validates :interest_rate, presence: true, numericality: { greater_than: 0 }
    validates :term_in_days, presence: true, numericality: { greater_than: 0 }
    validates :status, inclusion: { in: STATUSES }

  has_many :time_deposits, dependent: :restrict_with_error

  scope :active, -> { where(status: "active") }
  scope :by_term, -> { order(term_in_days: :asc) }
  end
end
