module Lending
  class RefinanceRestructure
    def initialize(loan, proposed_changes, options = {})
      @loan = loan
      @proposed_changes = proposed_changes.with_indifferent_access
      @options = options
    end

    def simulate
      payoff = LoanPayoffService.call(loan: @loan)

      new_rate = @proposed_changes[:interest_rate]&.to_f || @loan.interest_rate
      new_term = @proposed_changes[:term_months]&.to_i || @loan.term_months

      new_principal = payoff[:total_payoff_cents].to_f / 100

      schedules = RepaymentScheduleCalculator.call(
        amount: new_principal,
        interest_rate: new_rate,
        term_months: new_term,
        calculation: @loan.interest_calculation
      )

      {
        type: "refinance",
        payoff_amount: payoff[:total_payoff_cents].to_f / 100,
        payoff_breakdown: {
          outstanding_principal: payoff[:outstanding_principal_cents].to_f / 100,
          accrued_interest: payoff[:accrued_interest_cents].to_f / 100,
          penalties: payoff[:penalty_cents].to_f / 100
        },
        payoff_principal_cents: payoff[:outstanding_principal_cents],
        payoff_interest_cents: payoff[:accrued_interest_cents],
        new_principal: new_principal,
        new_interest_rate: new_rate,
        new_term_months: new_term,
        new_monthly_payment: schedules.first[:principal] + schedules.first[:interest],
        new_total_interest: schedules.sum { |s| s[:interest] }.round(2),
        proposed_schedule: schedules
      }
    end

    def execute!
      simulated = simulate

      ActiveRecord::Base.transaction do
        new_loan = Lending::Loan.create!(
          cooperative: @loan.cooperative,
          loan_application: @loan.loan_application,
          member: @loan.member,
          loan_product: @loan.loan_product,
          principal_cents: (simulated[:new_principal] * 100).round,
          interest_rate: simulated[:new_interest_rate],
          interest_calculation: @loan.interest_calculation,
          term_months: simulated[:new_term_months],
          outstanding_principal_cents: (simulated[:new_principal] * 100).round,
          status: "active",
          disbursed_at: Time.current,
          reference_number: "RF-#{@loan.reference_number}"
        )

        payoff_cents = (simulated[:payoff_amount] * 100).round

        LoanLinkService.call(
          from_loan: @loan,
          to_loan: new_loan,
          link_type: "refinance",
          amount_cents: payoff_cents,
          reason: "Refinanced #{@loan.reference_number} - payoff #{payoff_cents}"
        )

        principal_paid = [ payoff_cents, simulated[:payoff_principal_cents] || @loan.outstanding_principal_cents ].min
        interest_paid = [ payoff_cents - principal_paid, simulated[:payoff_interest_cents] || 0 ].min
        penalty_paid = payoff_cents - principal_paid - interest_paid

        Lending::LoanPayment.create!(
          cooperative: @loan.cooperative,
          loan: @loan,
          reference_number: "RF-PAY-#{@loan.reference_number}",
          amount_cents: payoff_cents,
          principal_cents: principal_paid,
          interest_cents: interest_paid,
          penalty_cents: penalty_paid,
          payment_date: Date.current
        )

        @loan.update!(
          outstanding_principal_cents: 0,
          status: "refinanced"
        )

        ScheduleVersioningService.call(
          loan: new_loan,
          new_schedule_data: simulated[:proposed_schedule].map { |s| s.transform_keys(&:to_s) },
          supersede_existing: false
        )

        { new_loan_id: new_loan.id, new_loan_reference: new_loan.reference_number, old_loan_status: "refinanced" }
      end
    end
  end
end
