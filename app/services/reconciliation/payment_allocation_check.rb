module Reconciliation
  class PaymentAllocationCheck < BaseCheck
    private

    def run_check
      failures = []
      scope = cooperative ? Lending::LoanPayment.where(cooperative: cooperative) : Lending::LoanPayment

      scope.find_each(batch_size: 100) do |payment|
        allocated = payment.principal_cents.to_i + payment.interest_cents.to_i + payment.penalty_cents.to_i
        if allocated != payment.amount_cents.to_i
          failures << {
            resource_type: "Lending::LoanPayment",
            resource_id: payment.id,
            reference_number: payment.reference_number,
            expected: payment.amount_cents,
            actual: allocated,
            diff: allocated - payment.amount_cents
          }
        end
      end
      failures
    end

    def total_count
      scope = cooperative ? Lending::LoanPayment.where(cooperative: cooperative) : Lending::LoanPayment
      scope.count
    end
  end
end
