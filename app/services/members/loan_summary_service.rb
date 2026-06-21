module Members
  class LoanSummaryService
    def initialize(member)
      @member = member
    end

    def call
      loans = Lending::Loan.where(member: @member)
        .includes(:loan_product, :loan_payments)
        .order(created_at: :desc)

      loan_applications = Lending::LoanApplication.where(member: @member)
        .includes(:loan_product)
        .order(created_at: :desc)

      {
        loans: loans,
        loan_applications: loan_applications,
        total_outstanding: loans.sum { |l| l.outstanding_principal_cents.to_i },
        active_count: loans.select(&:active?).size,
        total_count: loans.count
      }
    end
  end
end
