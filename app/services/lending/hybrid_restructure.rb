module Lending
  class HybridRestructure
    def initialize(loan, proposed_changes, options = {})
      @loan = loan
      @proposed_changes = proposed_changes.with_indifferent_access
      @options = options
    end

    def simulate
      payoff = LoanPayoffService.call(loan: @loan)
      arrears_to_capitalize = @proposed_changes[:arrears_cents]&.to_i || payoff[:accrued_interest_cents]
      partial_payoff = @proposed_changes[:partial_payoff_cents]&.to_i || 0
      new_rate = @proposed_changes[:interest_rate]&.to_f || @loan.interest_rate
      new_term = @proposed_changes[:term_months]&.to_i || @loan.term_months

      capitalized = [ arrears_to_capitalize, payoff[:accrued_interest_cents] ].min
      remaining_principal = [ @loan.outstanding_principal_cents - partial_payoff, 0 ].max
      new_principal_cents = remaining_principal + capitalized
      new_principal = new_principal_cents.to_f / 100

      creates_new_loan = @proposed_changes[:new_loan] == true

      schedules = RepaymentScheduleCalculator.call(
        amount: new_principal,
        interest_rate: new_rate,
        term_months: new_term,
        calculation: @loan.interest_calculation
      )

      {
        type: "hybrid",
        creates_new_loan: creates_new_loan,
        arrears_capitalized_cents: capitalized,
        partial_payoff_cents: partial_payoff,
        remaining_principal_cents: remaining_principal,
        new_principal_cents: new_principal_cents,
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
        if simulated[:creates_new_loan]
          execute_new_loan(simulated)
        else
          execute_modification(simulated)
        end
      end
    end

    private

    def execute_new_loan(simulated)
      new_loan = Lending::Loan.create!(
        cooperative: @loan.cooperative,
        loan_application: @loan.loan_application,
        member: @loan.member,
        loan_product: @loan.loan_product,
        principal_cents: simulated[:new_principal_cents],
        interest_rate: simulated[:new_interest_rate],
        interest_calculation: @loan.interest_calculation,
        term_months: simulated[:new_term_months],
        outstanding_principal_cents: simulated[:new_principal_cents],
        status: "active",
        disbursed_at: Time.current,
        reference_number: "HY-#{@loan.reference_number}"
      )

      LoanLinkService.call(
        from_loan: @loan,
        to_loan: new_loan,
        link_type: "hybrid",
        amount_cents: simulated[:new_principal_cents],
        reason: "Hybrid restructure - arrears capitalized: #{simulated[:arrears_capitalized_cents]}, partial pay: #{simulated[:partial_payoff_cents]}"
      )

      if simulated[:partial_payoff_cents] > 0
        Lending::LoanPayment.create!(
          cooperative: @loan.cooperative,
          loan: @loan,
          reference_number: "HY-PAY-#{@loan.reference_number}",
          amount_cents: simulated[:partial_payoff_cents],
          principal_cents: simulated[:partial_payoff_cents],
          interest_cents: 0,
          penalty_cents: 0,
          payment_date: Date.current
        )
      end

      @loan.update!(
        outstanding_principal_cents: [ @loan.outstanding_principal_cents - simulated[:partial_payoff_cents], 0 ].max,
        status: "hybrid_restructured"
      )

      ScheduleVersioningService.call(
        loan: new_loan,
        new_schedule_data: simulated[:proposed_schedule].map { |s| s.transform_keys(&:to_s) },
        supersede_existing: false
      )

      { new_loan_id: new_loan.id, new_loan_reference: new_loan.reference_number, old_loan_status: "hybrid_restructured" }
    end

    def execute_modification(simulated)
      remaining_cents = simulated[:new_principal_cents]

      ScheduleVersioningService.call(
        loan: @loan,
        new_schedule_data: simulated[:proposed_schedule].map { |s| s.transform_keys(&:to_s) }
      )

      if simulated[:partial_payoff_cents] > 0
        Lending::LoanPayment.create!(
          cooperative: @loan.cooperative,
          loan: @loan,
          reference_number: "HY-MOD-PAY-#{@loan.reference_number}",
          amount_cents: simulated[:partial_payoff_cents],
          principal_cents: simulated[:partial_payoff_cents],
          interest_cents: 0,
          penalty_cents: 0,
          payment_date: Date.current
        )
      end

      @loan.update!(
        outstanding_principal_cents: remaining_cents,
        interest_rate: simulated[:new_interest_rate],
        term_months: simulated[:new_term_months],
        status: "hybrid_restructured"
      )

      { loan_id: @loan.id, new_status: "hybrid_restructured", schedule_version: @loan.loan_schedules.active.first&.version }
    end
  end
end
