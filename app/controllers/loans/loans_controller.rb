module Loans
  class LoansController < ApplicationController
    layout "shell"

    def index
      @loans = Lending::Loan.includes(:member, :loan_product).order(created_at: :desc)
    end

    def show
      @loan = Lending::Loan.find(params[:id])
      @payment_schedule = @loan.payment_schedule
      @payments = @loan.loan_payments.order(:payment_date)
      @total_paid = @payments.sum(:principal_cents) + @payments.sum(:interest_cents) + @payments.sum(:penalty_cents)
    end
  end
end
