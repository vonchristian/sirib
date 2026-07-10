module Management
  class RestructuresController < Management::BaseController
    before_action -> { require_permission!(action: :approve, subject: :loan_restructure) }, only: [ :approve, :reject ]

    def index
      @cases = Lending::LoanRestructureCase.includes(:loan, :requested_by)
        .order(created_at: :desc)

      @pending_count = @cases.pending_decision.count
      @approved_count = @cases.approved.count
      @executed_count = @cases.executed.count
      @rejected_count = @cases.rejected.count

      @cases = @cases.where(status: params[:status]) if params[:status].present?
      @pagy, @cases = pagy(@cases)
    end

    def show
      @case = Lending::LoanRestructureCase.includes(:loan, :new_loan, :requested_by, :approved_by).find(params[:id])
      @loan = @case.loan
      @events = Lending::LoanEvent.where(loan: @loan).reverse_chronological.limit(50)
    end

    def approve
      @case = Lending::LoanRestructureCase.find(params[:id])
      @case.approve!(approver: Current.user)
      RestructureApproved.new(
        aggregate: @case.loan,
        actor: Current.user,
        restructure_case_id: @case.id,
        approved_by: Current.user.id,
        source: "management"
      ).tap(&:validate!).save!
      redirect_to management_restructure_path(@case), notice: "Restructure case approved."
    end

    def reject
      @case = Lending::LoanRestructureCase.find(params[:id])
      @case.reject!(approver: Current.user)
      RestructureRejected.new(
        aggregate: @case.loan,
        actor: Current.user,
        restructure_case_id: @case.id,
        rejected_by: Current.user.id,
        reason: params[:reason],
        source: "management"
      ).tap(&:validate!).save!
      redirect_to management_restructure_path(@case), notice: "Restructure case rejected."
    end
  end
end
