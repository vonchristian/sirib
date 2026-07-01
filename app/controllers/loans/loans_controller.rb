module Loans
  class LoansController < ApplicationController
    layout "shell"

    def index
      @loans = Lending::Loan.includes(:member, :loan_product).order(created_at: :desc)
      @active_count = @loans.active.count
      @restructured_count = @loans.restructured.count
      @defaulted_count = @loans.defaulted.count
      @total_count = @loans.count
    end

    def show
      @loan = Lending::Loan.includes(
        :loan_schedules, :loan_events, :outgoing_loan_links, :incoming_loan_links
      ).find(params[:id])
      @payment_schedule = @loan.payment_schedule
      @payments = @loan.loan_payments.order(:payment_date)
      @total_paid = @payments.sum(:principal_cents) + @payments.sum(:interest_cents) + @payments.sum(:penalty_cents)
      @events = @loan.loan_events.reverse_chronological.limit(20)
      @restructure_cases = @loan.loan_restructure_cases.order(created_at: :desc)
      @linked_loans = @loan.linked_loans
    end

    def restructure
      @loan = Lending::Loan.find(params[:id])
      unless @loan.restructurable?
        redirect_to loans_loan_path(@loan), alert: "Loan is not eligible for restructuring."
        return
      end
      @pending_cases = @loan.loan_restructure_cases.pending_decision
      @past_cases = @loan.loan_restructure_cases.executed
    end

    def timeline
      @loan = Lending::Loan.find(params[:id])
      @events = @loan.loan_events.reverse_chronological
      @schedules = @loan.loan_schedules.order(version: :desc)
      @links = @loan.outgoing_loan_links.includes(:to_loan) + @loan.incoming_loan_links.includes(:from_loan)
      @links.sort_by!(&:created_at)
    end
  end
end
