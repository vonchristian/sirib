module Reconciliation
  class LoanPrincipalIntegrityCheck < BaseCheck
    private

    def run_check
      failures = []
      scope = Lending::Loan.where(cooperative: cooperative).active if cooperative
      scope ||= Lending::Loan.active

      scope.find_each(batch_size: 100) do |loan|
        total_principal_paid = loan.loan_payments.sum(:principal_cents)
        expected_outstanding = loan.principal_cents - total_principal_paid
        if loan.outstanding_principal_cents != expected_outstanding
          failures << {
            resource_type: "Lending::Loan",
            resource_id: loan.id,
            reference_number: loan.reference_number,
            expected: expected_outstanding,
            actual: loan.outstanding_principal_cents,
            diff: loan.outstanding_principal_cents - expected_outstanding
          }
        end
      end
      failures
    end

    def total_count
      scope = cooperative ? Lending::Loan.where(cooperative: cooperative).active : Lending::Loan.active
      scope.count
    end
  end
end
