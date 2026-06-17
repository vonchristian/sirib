module Treasury
  class SavingsAccountsController < ApplicationController
    layout "dashboard"

    def index
      @accounts = Treasury::SavingsAccount.includes(:savings_product, :depositor).by_latest
    end

    def new
      @account = Treasury::SavingsAccount.new
      @products = Treasury::SavingsProduct.active.by_name
    end

    def create
      @account = Treasury::SavingsAccount.new(account_params)
      @account.depositor = Member.find(account_params[:depositor_id]) if account_params[:depositor_id].present?

      if @account.save
        redirect_to treasury_savings_account_path(@account), notice: "Savings account opened."
      else
        @products = Treasury::SavingsProduct.active.by_name
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @account = Treasury::SavingsAccount.find(params[:id])
      @transactions = @account.transactions.by_latest
      @month_transactions = @account.transactions.where(posted_at: Time.current.beginning_of_month..)
      @month_deposits = @month_transactions.deposit.sum(:amount_cents)
      @month_withdrawals = @month_transactions.withdraw.sum(:amount_cents)
    end

    def deposit
      @account = Treasury::SavingsAccount.find(params[:id])
      @cash_accounts = cash_accounts_for_select

      redirect_to treasury_savings_account_path(@account), alert: "No cash accounts are linked to your profile. Contact an administrator." if @cash_accounts.empty?
    end

    def preview_deposit
      @account = Treasury::SavingsAccount.find(params[:id])
      @cash_accounts = cash_accounts_for_select

      if @cash_accounts.empty?
        redirect_to treasury_savings_account_path(@account), alert: "No cash accounts are linked to your profile. Contact an administrator."
        return
      end

      @amount = parse_amount(params[:amount_cents])
      @cash_account = resolve_cash_account
      @notes = params[:notes]

      unless @amount.cents.positive?
        flash.now[:alert] = "Amount must be greater than zero."
        render :deposit, status: :unprocessable_entity
        return
      end

      unless @cash_account
        flash.now[:alert] = "Select a cash on hand account."
        render :deposit, status: :unprocessable_entity
        return
      end

      @debits = [{ account: @cash_account, amount: @amount }]
      @credits = [{ account: @account.liability_account, amount: @amount }]
    end

    def confirm_deposit
      @account = Treasury::SavingsAccount.find(params[:id])
      @amount = parse_amount(params[:amount_cents])
      @cash_account = resolve_cash_account
      @notes = params[:notes]

      unless @amount.cents.positive? && @cash_account
        redirect_to deposit_treasury_savings_account_path(@account), alert: "Invalid deposit parameters."
        return
      end

      unless Current.cash_session
        redirect_to deposit_treasury_savings_account_path(@account), alert: "No active cash session. Please log in again."
        return
      end

      outcome = Treasury::CashSessionService.deposit(
        cash_session: Current.cash_session,
        savings_account: @account,
        amount: @amount,
        cash_account: @cash_account,
        notes: @notes
      )

      if outcome.valid?
        redirect_to treasury_savings_account_path(@account), notice: "Deposit of #{@amount.format} completed."
      else
        redirect_to deposit_treasury_savings_account_path(@account), alert: outcome.errors.join(", ")
      end
    end

    def withdraw
      @account = Treasury::SavingsAccount.find(params[:id])
      @cash_accounts = cash_accounts_for_select

      redirect_to treasury_savings_account_path(@account), alert: "No cash accounts are linked to your profile. Contact an administrator." if @cash_accounts.empty?
    end

    def preview_withdraw
      @account = Treasury::SavingsAccount.find(params[:id])
      @cash_accounts = cash_accounts_for_select

      if @cash_accounts.empty?
        redirect_to treasury_savings_account_path(@account), alert: "No cash accounts are linked to your profile. Contact an administrator."
        return
      end

      @amount = parse_amount(params[:amount_cents])
      @cash_account = resolve_cash_account
      @notes = params[:notes]

      unless @amount.cents.positive?
        flash.now[:alert] = "Amount must be greater than zero."
        render :withdraw, status: :unprocessable_entity
        return
      end

      unless @cash_account
        flash.now[:alert] = "Select a cash on hand account."
        render :withdraw, status: :unprocessable_entity
        return
      end

      if @amount > @account.balance
        flash.now[:alert] = "Insufficient balance. Available: #{@account.balance.format}"
        render :withdraw, status: :unprocessable_entity
        return
      end

      @debits = [{ account: @account.liability_account, amount: @amount }]
      @credits = [{ account: @cash_account, amount: @amount }]
    end

    def confirm_withdraw
      @account = Treasury::SavingsAccount.find(params[:id])
      @amount = parse_amount(params[:amount_cents])
      @cash_account = resolve_cash_account
      @notes = params[:notes]

      unless @amount.cents.positive? && @cash_account
        redirect_to withdraw_treasury_savings_account_path(@account), alert: "Invalid withdrawal parameters."
        return
      end

      unless Current.cash_session
        redirect_to withdraw_treasury_savings_account_path(@account), alert: "No active cash session. Please log in again."
        return
      end

      if @amount > @account.balance
        redirect_to withdraw_treasury_savings_account_path(@account), alert: "Insufficient balance."
        return
      end

      outcome = Treasury::CashSessionService.withdraw(
        cash_session: Current.cash_session,
        savings_account: @account,
        amount: @amount,
        cash_account: @cash_account,
        notes: @notes
      )

      if outcome.valid?
        redirect_to treasury_savings_account_path(@account), notice: "Withdrawal of #{@amount.format} completed."
      else
        redirect_to withdraw_treasury_savings_account_path(@account), alert: outcome.errors.join(", ")
      end
    end

    private

    def account_params
      params.require(:treasury_savings_account).permit(:savings_product_id, :depositor_id, :account_type)
    end

    def parse_amount(raw)
      cents = (raw.to_f * 100).round
      Money.new(cents, "PHP")
    end

    def cash_accounts_for_select
      accounts = Current.user.cash_accounts.includes(:account).map(&:account).compact
      @single_cash_account = accounts.first if accounts.size == 1
      accounts
    end

    def resolve_cash_account
      if params[:cash_account_id].present?
        Accounting::Account.find_by(id: params[:cash_account_id])
      else
        cash_accounts_for_select.first
      end
    end
  end
end
