module Treasury
  class TimeDeposit < ApplicationRecord
    self.table_name = "treasury_time_deposits"

    monetize :amount_cents
    monetize :interest_earned_cents

    STATUSES = %w[pending active matured closed].freeze

    belongs_to :depositor, polymorphic: true
    belongs_to :time_deposit_product

    def active?
      status == "active"
    end

    validates :amount_cents, presence: true, numericality: { greater_than: 0 }
    validates :interest_rate, presence: true, numericality: { greater_than: 0 }
    validates :status, inclusion: { in: STATUSES }

    scope :pending, -> { where(status: "pending") }
    scope :active, -> { where(status: "active") }
    scope :by_latest, -> { order(created_at: :desc) }
  end
end
