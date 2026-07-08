class PaymentAllocator
  def self.call(loan:, amount_cents:, payment_date:)
    new(loan, amount_cents, payment_date).call
  end

  def initialize(loan, amount_cents, payment_date)
    @loan = loan
    @amount_cents = amount_cents.to_i
    @payment_date = payment_date
    @remaining = @amount_cents
  end

  def call
    overdue_interest = calculate_overdue_interest
    overdue_principal = calculate_overdue_principal

    allocation = { penalty_cents: 0, interest_cents: 0, principal_cents: 0 }

    # 1st: penalty (if any)
    if overdue_principal > 0 || overdue_interest > 0
      penalty = [ @remaining, (overdue_interest * 0.02).round ].min
      allocation[:penalty_cents] = penalty
      @remaining -= penalty
    end

    # 2nd: overdue interest
    interest = [ @remaining, overdue_interest ].min
    allocation[:interest_cents] = interest
    @remaining -= interest

    # 3rd: overdue principal
    principal = [ @remaining, overdue_principal ].min
    allocation[:principal_cents] = principal
    @remaining -= principal

    # 4th: future installments (principal)
    allocation[:principal_cents] += @remaining

    allocation
  end

  private

  def calculate_overdue_interest
    schedules = @loan.payment_schedule
    total_interest = schedules
      .select { |s| s.due_date < @payment_date }
      .sum(&:interest_cents)
    paid_interest = @loan.loan_payments.sum(:interest_cents)
    [ total_interest - paid_interest, 0 ].max
  end

  def calculate_overdue_principal
    schedules = @loan.payment_schedule
    total_principal = schedules
      .select { |s| s.due_date < @payment_date }
      .sum(&:principal_cents)
    paid_principal = @loan.loan_payments.sum(:principal_cents)
    [ total_principal - paid_principal, 0 ].max
  end
end
