module Lending
  class ModificationRestructure
    def initialize(loan, proposed_changes, options = {})
      @loan = loan
      @proposed_changes = proposed_changes.with_indifferent_access
      @options = options
    end

    def simulate
      new_rate = @proposed_changes[:interest_rate]&.to_f || @loan.interest_rate
      new_term = @proposed_changes[:term_months]&.to_i || @loan.term_months
      grace_period = @proposed_changes[:grace_period_months]&.to_i || 0
      outstanding = @loan.outstanding_principal_cents.to_f / 100

      schedules = RepaymentScheduleCalculator.call(
        amount: outstanding,
        interest_rate: new_rate,
        term_months: new_term,
        calculation: @loan.interest_calculation
      )

      old_payment = compute_old_payment
      new_payment = schedules.first[:principal] + schedules.first[:interest]

      old_total_interest = compute_old_total_interest
      new_total_interest = schedules.sum { |s| s[:interest] }

      {
        type: "modification",
        new_interest_rate: new_rate,
        new_term_months: new_term,
        grace_period_months: grace_period,
        new_monthly_payment: new_payment.round(2),
        old_monthly_payment: old_payment[:amount],
        payment_change: (new_payment - old_payment[:amount]).round(2),
        payment_change_pct: old_payment[:amount] > 0 ? (((new_payment - old_payment[:amount]) / old_payment[:amount]) * 100).round(1) : 0,
        new_total_interest: new_total_interest.round(2),
        old_total_interest: old_total_interest,
        interest_impact: (new_total_interest - old_total_interest).round(2),
        proposed_schedule: schedules
      }
    end

    def execute!
      simulated = simulate
      schedule_data = simulated[:proposed_schedule]

      ScheduleVersioningService.call(
        loan: @loan,
        new_schedule_data: schedule_data.map { |s| s.transform_keys(&:to_s) }
      )

      if @proposed_changes[:interest_rate].present?
        @loan.update!(interest_rate: @proposed_changes[:interest_rate].to_f)
      end
      if @proposed_changes[:term_months].present?
        @loan.update!(term_months: @proposed_changes[:term_months].to_i)
      end

      @loan.update!(status: "modified")

      { schedule_version: @loan.loan_schedules.active.first&.version, new_status: "modified" }
    end

    private

    def compute_old_payment
      schedules = @loan.payment_schedule
      return { amount: 0 } if schedules.empty?

      first = schedules.first
      { amount: (first.principal_cents.to_f + first.interest_cents.to_f) / 100 }
    end

    def compute_old_total_interest
      @loan.payment_schedule.sum { |s| s.interest_cents.to_f / 100 }
    end
  end
end
