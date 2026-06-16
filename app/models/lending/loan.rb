module Lending
  class Loan < ApplicationRecord
    self.table_name = "loans"

    belongs_to :loan_application
    belongs_to :member
    belongs_to :loan_product
    has_many :loan_payments, dependent: :restrict_with_error

    validates :principal_cents, numericality: { greater_than: 0 }
    validates :interest_rate, numericality: { greater_than: 0 }
    validates :interest_calculation, inclusion: { in: %w[straight_line declining_balance] }
    validates :term_months, numericality: { greater_than: 0 }
    validates :outstanding_principal_cents, numericality: { greater_than_or_equal_to: 0 }
    validates :status, inclusion: { in: %w[active paid defaulted written_off] }
    validates :reference_number, uniqueness: true

    before_validation :assign_reference_number, on: :create

    scope :active, -> { where(status: "active") }
    scope :for_disbursement, -> { where(status: "active", disbursed_at: nil) }

    def disbursed?
      disbursed_at.present?
    end

    def payment_schedule
      loan_application.loan_repayment_schedules.order(:sequence)
    end

    private

    def assign_reference_number
      return if reference_number.present?
      self.reference_number = "LN-#{Time.current.strftime("%Y%m%d")}-#{SecureRandom.hex(3).upcase}"
    end
  end
end
