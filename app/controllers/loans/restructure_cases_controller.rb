module Loans
  class RestructureCasesController < ApplicationController
    layout "shell"

    def index
      @cases = Lending::LoanRestructureCase.includes(:loan, :requested_by)
        .order(created_at: :desc)

      @pending_count = @cases.pending_decision.count
      @approved_count = @cases.approved.count
      @executed_count = @cases.executed.count
      @total_cases = @cases.count

      @cases = @cases.where(status: params[:status]) if params[:status].present?
      @cases = @cases.by_type(params[:type]) if params[:type].present?

      @pagy, @cases = pagy(@cases)
    end

    def show
      @case = Lending::LoanRestructureCase.includes(:loan, :new_loan, :requested_by, :approved_by).find(params[:id])
      @loan = @case.loan
      @events = Lending::LoanEvent.where(loan: @loan).reverse_chronological.limit(50)
    end
  end
end
