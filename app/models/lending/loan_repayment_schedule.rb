module Lending
  class LoanRepaymentSchedule < ApplicationRecord
    self.table_name = "loan_repayment_schedules"

    belongs_to :loan_application

    validates :sequence, presence: true, uniqueness: { scope: :loan_application_id }
    validates :due_date, presence: true
    validates :principal_cents, numericality: { greater_than_or_equal_to: 0 }
    validates :interest_cents, numericality: { greater_than_or_equal_to: 0 }

    def total_cents
      principal_cents + interest_cents
    end
  end
end
