module External
  class ReconciliationController < BaseController
    before_action { set_active_nav }
    before_action :set_bank
    before_action :set_account

    def show
      @transactions = @account.transactions.by_date.includes(:document)
      @transactions = @transactions.unreconciled if params[:unreconciled] == "1"
      @transactions = @transactions.limit(100) unless params[:all]

      @journal_entries = Accounting::Entry.order(posted_at: :desc).limit(100)

      if params[:transaction_id]
        @selected_transaction = @account.transactions.find(params[:transaction_id])
        @selected_allocations = @selected_transaction.allocations.includes(:journal_entry, :created_by)
      end
    end

    def allocate
      @transaction = @account.transactions.find(params[:transaction_id])
      @journal_entry = Accounting::Entry.find(params[:journal_entry_id])

      allocated_amount_cents = params[:allocated_amount_cents].to_i

      @allocation = @transaction.allocate_to_entry!(
        @journal_entry,
        amount_cents: allocated_amount_cents,
        status: params[:status]&.to_sym || :suggested,
        confidence_score: params[:confidence_score]&.to_f,
        user: Current.user
      )

      External::ReconciliationAuditJob.perform_later(
        @allocation,
        "created",
        Current.user.id
      )

      redirect_to external_bank_account_reconciliation_path(
        @bank,
        @account,
        transaction_id: @transaction.id
      ), notice: "Allocation created successfully."
    end

    def confirm_allocation
      @allocation = External::BankTransactionAllocation.find(params[:allocation_id])
      @allocation.confirm!

      External::ReconciliationAuditJob.perform_later(
        @allocation,
        "confirmed",
        Current.user.id
      )

      redirect_to external_bank_account_reconciliation_path(
        @bank,
        @account,
        transaction_id: @allocation.external_bank_transaction_id
      ), notice: "Allocation confirmed."
    end

    def reject_allocation
      @allocation = External::BankTransactionAllocation.find(params[:allocation_id])
      @allocation.reject!

      External::ReconciliationAuditJob.perform_later(
        @allocation,
        "rejected",
        Current.user.id
      )

      redirect_to external_bank_account_reconciliation_path(
        @bank,
        @account,
        transaction_id: @allocation.external_bank_transaction_id
      ), notice: "Allocation rejected."
    end

    private

    def set_bank
      @bank = External::Bank.find(params[:bank_id])
    end

    def set_account
      @account = @bank.accounts.find(params[:account_id])
    end
  end
end
