module Lending
  class AgingCalculationService
    def self.call(loan:, as_of: Date.current)
      new(loan, as_of).call
    end

    def self.refresh_all(as_of: Date.current)
      Lending::Loan.active.find_each do |loan|
        call(loan: loan, as_of: as_of)
      end
    end

    def initialize(loan, as_of)
      @loan = loan
      @as_of = as_of
    end

    def call
      schedules = @loan.payment_schedule
      payments = @loan.loan_payments.order(:payment_date)

      oldest_unpaid = find_oldest_unpaid_schedule(schedules, payments)

      if oldest_unpaid.nil?
        dpd = 0
        oldest_due_date = nil
      else
        dpd = [ (@as_of - oldest_unpaid.due_date).to_i, 0 ].max
        oldest_due_date = oldest_unpaid.due_date
      end

      group = Lending::LoanAgingGroup.find_bucket(dpd, cooperative_id: @loan.cooperative_id) ||
              Lending::LoanAgingGroup.active.where(cooperative_id: @loan.cooperative_id).ordered.last

      LoanAging.transaction do
        aging = Lending::LoanAging.find_or_initialize_by(loan: @loan)
        aging.cooperative ||= @loan.cooperative
        aging.update!(
          loan_aging_group: group,
          days_past_due: dpd,
          oldest_unpaid_due_date: oldest_due_date,
          outstanding_principal_cents: compute_outstanding_principal,
          outstanding_interest_cents: compute_outstanding_interest,
          penalty_amount_cents: compute_penalty,
          total_exposure_cents: compute_total_exposure,
          calculated_at: Time.current
        )
        aging
      end
    end

    private

    def find_oldest_unpaid_schedule(schedules, payments)
      total_paid_principal = payments.sum(:principal_cents)
      remaining = total_paid_principal

      schedules.order(:due_date, :sequence).each do |schedule|
        if remaining >= schedule.principal_cents
          remaining -= schedule.principal_cents
        else
          return schedule
        end
      end

      nil
    end

    def compute_outstanding_principal
      [ @loan.outstanding_principal_cents, 0 ].max
    end

    def compute_outstanding_interest
      schedules = @loan.payment_schedule
      total_interest = schedules.sum(:interest_cents)
      paid_interest = @loan.loan_payments.sum(:interest_cents)
      [ total_interest - paid_interest, 0 ].max
    end

    def compute_penalty
      overdue_schedules = @loan.payment_schedule.select { |s| s.due_date < @as_of }
      overdue_interest = overdue_schedules.sum(&:interest_cents)
      paid_interest = @loan.loan_payments.sum(:interest_cents)
      net_overdue = [ overdue_interest - paid_interest, 0 ].max
      (net_overdue * 0.02).round
    end

    def compute_total_exposure
      compute_outstanding_principal + compute_outstanding_interest + compute_penalty
    end
  end
end
