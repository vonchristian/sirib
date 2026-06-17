module Equity
  class AccountsController < ApplicationController
    layout "dashboard"

    def index
      @accounts = Equity::Account.includes(:member, :share_product).by_latest
    end

    def new
      @account = Equity::Account.new
      @products = Equity::Product.active.by_name
      @members = Member.order(:last_name)
    end

    def create
      outcome = Equity::OpenAccountService.run(
        member: Member.find(account_params[:member_id]),
        share_product: Equity::Product.find(account_params[:share_product_id]),
        opened_by_id: Current.user.id,
        branch: account_params[:branch],
        remarks: account_params[:remarks]
      )

      if outcome.valid?
        redirect_to equity_account_path(outcome.result), notice: "Share capital account opened."
      else
        @account = Equity::Account.new(account_params)
        @products = Equity::Product.active.by_name
        @members = Member.order(:last_name)
        flash.now[:alert] = outcome.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @account = Equity::Account.includes(:member, :share_product, transactions: :entry).find(params[:id])
      @transactions = @account.transactions.by_latest
      @cash_accounts = cash_accounts_for_select
    end

    def buy
      @account = Equity::Account.find(params[:id])
      @cash_accounts = cash_accounts_for_select

      if @cash_accounts.empty?
        redirect_to equity_account_path(@account), alert: "No cash accounts are linked to your profile. Contact an administrator."
      end
    end

    def preview_buy
      @account = Equity::Account.find(params[:id])
      @cash_accounts = cash_accounts_for_select

      if @cash_accounts.empty?
        redirect_to equity_account_path(@account), alert: "No cash accounts are linked to your profile. Contact an administrator."
        return
      end

      @shares = params[:shares].to_i
      @product = @account.share_product
      @cash_account = resolve_cash_account
      @notes = params[:notes]

      unless @shares.positive?
        flash.now[:alert] = "Number of shares must be greater than zero."
        render :buy, status: :unprocessable_entity
        return
      end

      unless @cash_account
        flash.now[:alert] = "Select a cash on hand account."
        render :buy, status: :unprocessable_entity
        return
      end

      if @account.shares_owned.zero? && @shares < @product.minimum_initial_purchase
        flash.now[:alert] = "Minimum initial purchase is #{@product.minimum_initial_purchase} shares."
        render :buy, status: :unprocessable_entity
        return
      end

      @total_amount = Money.new(@shares * @product.price_per_share_cents, "PHP")
      @price_per_share = @product.price_per_share

      @debits = [{ account: @cash_account.name, amount: @total_amount.format }]
      @credits = [{ account: @account.equity_account&.name || "Share Capital Equity", amount: @total_amount.format }]

      render :buy
    end

    def confirm_buy
      @account = Equity::Account.find(params[:id])
      @shares = params[:shares].to_i
      @cash_account = resolve_cash_account
      @notes = params[:notes]

      unless @shares.positive? && @cash_account
        redirect_to buy_equity_account_path(@account), alert: "Invalid purchase parameters."
        return
      end

      outcome = Equity::BuySharesService.run(
        share_capital_account: @account,
        shares: @shares,
        cash_account: @cash_account,
        posted_by_id: Current.user.id,
        notes: @notes
      )

      if outcome.valid?
        redirect_to equity_account_path(@account), notice: "Successfully purchased #{@shares} shares."
      else
        redirect_to buy_equity_account_path(@account), alert: outcome.errors.full_messages.to_sentence
      end
    end

    private

    def account_params
      params.require(:equity_account).permit(:member_id, :share_product_id, :branch, :remarks)
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
