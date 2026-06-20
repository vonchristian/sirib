module External
  class AccountsController < BaseController
    before_action { set_active_nav }
    before_action :set_bank
    before_action :set_account, only: [:show, :edit, :update, :destroy]

    def index
      @accounts = @bank.accounts.order(created_at: :desc)
    end

    def new
      @account = @bank.accounts.new
    end

    def create
      @account = @bank.accounts.new(account_params)

      if @account.save
        @account.create_tracking_accounts
        redirect_to external_bank_account_path(@bank, @account), notice: "Account was successfully created."
      else
        render :new, status: :unprocessable_entity
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
        render :edit, status: :unprocessable_entity
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