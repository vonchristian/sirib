module Loans
  class PaymentsController < ApplicationController
    layout "shell"

    def create
      @loan = Lending::Loan.find(params[:loan_id])
      amount_cents = (params[:amount].to_f * 100).round
      payment_date = Date.current

      allocation = PaymentAllocator.call(
        loan: @loan,
        amount_cents: amount_cents,
        payment_date: payment_date
      )

      @payment = @loan.loan_payments.new(
        amount_cents: amount_cents,
        principal_cents: allocation[:principal_cents],
        interest_cents: allocation[:interest_cents],
        penalty_cents: allocation[:penalty_cents],
        payment_date: payment_date
      )

      if @payment.save
        new_outstanding = @loan.outstanding_principal_cents - @payment.principal_cents
        @loan.update!(outstanding_principal_cents: [new_outstanding, 0].max)
        @loan.update!(status: "paid") if @loan.outstanding_principal_cents <= 0
        redirect_to loans_loan_path(@loan), notice: "Payment recorded. Allocated: #{@payment.principal_cents} principal, #{@payment.interest_cents} interest, #{@payment.penalty_cents} penalties."
      else
        redirect_to loans_loan_path(@loan), alert: @payment.errors.full_messages.join(", ")
      end
    end
  end
end
