module Loans
  class RestructuresController < ApplicationController
    layout "shell"

    before_action :set_loan, only: [ :new, :create, :simulate ]
    before_action :set_restructure_case, only: [ :show, :submit, :approve, :reject, :execute ]

    def new
      @restructure_type = params[:type]
      unless %w[modification refinance hybrid].include?(@restructure_type)
        redirect_to restructure_loans_loan_path(@loan), alert: "Invalid restructure type."
        return
      end
      @case = Lending::LoanRestructureCase.new(
        loan: @loan,
        restructure_type: @restructure_type,
        proposed_changes: {}
      )
      @simulation = simulate_restructure(@restructure_type, {}) if params[:simulate] == "true"
    end

    def create
      @restructure_type = restructure_params[:restructure_type]
      @case = Lending::LoanRestructureService.call(
        type: @restructure_type,
        loan: @loan,
        proposed_changes: restructure_params[:proposed_changes] || {},
        notes: restructure_params[:notes]
      )

      redirect_to loans_restructure_path(@case), notice: "Restructure case created."
    rescue => e
      flash.now[:alert] = e.message
      @case ||= Lending::LoanRestructureCase.new(
        loan: @loan,
        restructure_type: @restructure_type,
        proposed_changes: restructure_params[:proposed_changes] || {}
      )
      render :new, status: :unprocessable_entity
    end

    def show
      @loan = @case.loan
      @simulation = fetch_simulation
    end

    def submit
      @case.submit!
      Lending::LoanEvent.create!(
        loan: @case.loan,
        actor: Current.user,
        event_type: "restructure_submitted",
        metadata: { restructure_case_id: @case.id }
      )
      redirect_to loans_restructure_path(@case), notice: "Restructure case submitted for approval."
    end

    def approve
      @case.approve!(approver: Current.user)
      Lending::LoanEvent.create!(
        loan: @case.loan,
        actor: Current.user,
        event_type: "restructure_approved",
        metadata: { restructure_case_id: @case.id, approved_by: Current.user.id }
      )
      redirect_to loans_restructure_path(@case), notice: "Restructure case approved."
    end

    def reject
      @case.reject!(approver: Current.user)
      Lending::LoanEvent.create!(
        loan: @case.loan,
        actor: Current.user,
        event_type: "restructure_rejected",
        metadata: { restructure_case_id: @case.id, rejected_by: Current.user.id, reason: params[:reason] }
      )
      redirect_to loans_restructure_path(@case), notice: "Restructure case rejected."
    end

    def execute
      unless @case.approved?
        redirect_to loans_restructure_path(@case), alert: "Case must be approved before execution." and return
      end

      service = Lending::LoanRestructureService.new(
        @case.restructure_type,
        @case.loan,
        @case.proposed_changes,
        Current.user,
        {}
      )
      result = service.execute(restructure_case: @case)
      redirect_to loans_restructure_path(@case), notice: "Restructure executed successfully."
    rescue => e
      @case.fail!
      redirect_to loans_restructure_path(@case), alert: "Execution failed: #{e.message}"
    end

    def simulate
      @restructure_type = params[:type] || restructure_params[:restructure_type]
      @simulation = simulate_restructure(@restructure_type, restructure_params[:proposed_changes] || {})

      respond_to do |format|
        format.html { render partial: "loans/restructures/simulation_panel", locals: { simulation: @simulation } }
        format.json { render json: @simulation }
      end
    rescue => e
      respond_to do |format|
        format.json { render json: { error: e.message }, status: :unprocessable_entity }
        format.html { render plain: e.message, status: :unprocessable_entity }
      end
    end

    private

    def set_loan
      @loan = Lending::Loan.find(params[:loan_id])
    end

    def set_restructure_case
      @case = Lending::LoanRestructureCase.find(params[:id])
    end

    def restructure_params
      params.require(:lending_loan_restructure_case).permit(
        :restructure_type, :notes,
        proposed_changes: {}
      )
    end

    def simulate_restructure(type, changes)
      Lending::LoanRestructureService.new(type, @loan, changes, Current.user, {}).simulate
    end

    def fetch_simulation
      Lending::LoanRestructureService.new(
        @case.restructure_type, @case.loan, @case.proposed_changes, Current.user, {}
      ).simulate
    rescue
      nil
    end
  end
end
