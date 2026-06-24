module Lending
  class LoanPayoffService
    def self.call(loan:, as_of: Date.current)
      new(loan, as_of).call
    end

    def initialize(loan, as_of)
      @loan = loan
      @as_of = as_of
    end

    def call
      schedules = @loan.payment_schedule
      total_principal = @loan.principal_cents
      total_interest = schedules.sum(&:interest_cents)

      paid_principal = @loan.loan_payments.sum(:principal_cents)
      paid_interest = @loan.loan_payments.sum(:interest_cents)
      paid_penalties = @loan.loan_payments.sum(:penalty_cents)

      outstanding_principal = [ total_principal - paid_principal, 0 ].max
      overdue_schedules = schedules.select { |s| s.due_date < @as_of }

      accrued_interest = [ total_interest - paid_interest, 0 ].max
      overdue_interest = overdue_schedules.sum(&:interest_cents) - paid_interest
      overdue_interest = [ overdue_interest, 0 ].max

      penalty_rate = 0.02
      penalty_cents = (overdue_interest * penalty_rate).round

      total_payoff = outstanding_principal + accrued_interest + penalty_cents

      {
        outstanding_principal_cents: outstanding_principal,
        accrued_interest_cents: accrued_interest,
        overdue_interest_cents: overdue_interest,
        penalty_cents: penalty_cents,
        total_payoff_cents: total_payoff,
        paid_principal_cents: paid_principal,
        paid_interest_cents: paid_interest,
        paid_penalties_cents: paid_penalties,
        as_of: @as_of
      }
    end
  end
end
