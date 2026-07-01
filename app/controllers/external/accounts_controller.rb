module External
  class AccountsController < BaseController
    before_action { set_active_nav }
    before_action :set_bank, unless: -> { params[:bank_id].blank? && %w[index new create].include?(action_name) }
    before_action :set_account, only: [ :show, :edit, :update, :destroy ]

    def index
      if @bank
        @accounts = @bank.accounts.includes(:bank).order(created_at: :desc)
      else
        @accounts = External::BankAccount.includes(:bank).order(:account_name)
      end
    end

    def new
      @banks = External::Bank.active.order(:name)
      @account = @bank ? @bank.accounts.new : External::BankAccount.new
    end

    def create
      @banks = External::Bank.active.order(:name)
      bank = find_or_set_bank
      @account = bank.accounts.new(account_params)

      if @account.save
        redirect_to external_bank_account_path(bank, @account), notice: "Account was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def show
      @transactions = @account.transactions.by_date_desc
      @transactions = @transactions.limit(50) unless params[:all]

      @documents = @account.documents.order(created_at: :desc).limit(10)
    end

    def edit
    end

    def update
      if @account.update(account_params)
        redirect_to external_bank_account_path(@bank, @account), notice: "Account was successfully updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @account.update!(status: :inactive)

      redirect_to external_bank_accounts_path(@bank), notice: "Account was successfully deactivated."
    end

    private

    def set_bank
      @bank = External::Bank.find(params[:bank_id])
    end

    def find_or_set_bank
      id = params[:external_bank_account]&.delete(:external_bank_id) || params[:bank_id]
      External::Bank.find(id)
    end

    def set_account
      @account = @bank.accounts.find(params[:id])
    end

    def account_params
      params.require(:external_bank_account).permit(
        :account_name,
        :account_number_encrypted,
        :account_type,
        :currency,
        :status
      )
    end
  end
end
