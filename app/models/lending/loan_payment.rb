module Lending
  class LoanPayment < ApplicationRecord
    self.table_name = "loan_payments"
    include CooperativeScoped

    monetize :amount_cents
    monetize :principal_cents
    monetize :interest_cents
    monetize :penalty_cents

    belongs_to :loan
    belongs_to :entry, class_name: "Accounting::Entry", optional: true

    validates :reference_number, presence: true, uniqueness: { scope: :cooperative_id }
    validates :amount_cents, numericality: { greater_than: 0 }
    validates :principal_cents, numericality: { greater_than_or_equal_to: 0 }
    validates :interest_cents, numericality: { greater_than_or_equal_to: 0 }
    validates :penalty_cents, numericality: { greater_than_or_equal_to: 0 }
    validates :payment_date, presence: true

    before_validation :assign_reference_number, on: :create
    validate :allocation_equals_amount

    after_commit :recalculate_loan_aging, on: [ :create, :update ]

    private

    def recalculate_loan_aging
      Lending::AgingCalculationService.call(loan: loan)
    end

    def assign_reference_number
      return if reference_number.present?
      self.reference_number = "PAY-#{Time.current.strftime("%Y%m%d")}-#{SecureRandom.hex(3).upcase}"
    end

    def allocation_equals_amount
      total = principal_cents.to_i + interest_cents.to_i + penalty_cents.to_i
      if total != amount_cents.to_i
        errors.add(:base, "Payment allocation (#{total}) must equal payment amount (#{amount_cents})")
      end
    end
  end
end
