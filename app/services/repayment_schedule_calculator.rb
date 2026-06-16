class RepaymentScheduleCalculator
  def self.call(amount:, interest_rate:, term_months:, calculation:)
    new(amount, interest_rate, term_months, calculation).call
  end

  def initialize(amount, interest_rate, term_months, calculation)
    @amount = amount
    @monthly_rate = interest_rate / 100.0 / 12
    @term = term_months
    @calculation = calculation
  end

  def call
    case @calculation
    when "straight_line" then straight_line
    when "declining_balance" then declining_balance
    else straight_line
    end
  end

  private

  def straight_line
    monthly_principal = @amount / @term
    monthly_interest = @amount * @monthly_rate
    total_interest = monthly_interest * @term
    final_principal = @amount

    @term.times.map do |i|
      is_last = i == @term - 1
      remaining = @amount - (monthly_principal * i)
      interest = remaining * @monthly_rate

      {
        principal: is_last ? final_principal - (monthly_principal * i) : monthly_principal,
        interest: is_last ? total_interest - (monthly_interest * i) : interest.round(2)
      }
    end
  end

  def declining_balance
    factor = (1 + @monthly_rate) ** @term
    payment = @amount * (@monthly_rate * factor) / (factor - 1)

    remaining = @amount
    @term.times.map do |i|
      interest = remaining * @monthly_rate
      principal = payment - interest
      remaining -= principal

      if i == @term - 1
        { principal: remaining + principal, interest: interest.round(2) }
      else
        { principal: principal.round(2), interest: interest.round(2) }
      end
    end
  end
end
