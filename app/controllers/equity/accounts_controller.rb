module Equity
  class AccountsController < ApplicationController
    layout "shell"

    def index
      @accounts = Equity::Account.includes(:member, :share_product).by_latest
    end

    def new
      @account = Equity::Account.new
      @products = Equity::Product.active.by_name
      @members = Membership::Member.order(:last_name)
    end

    def create
      outcome = Equity::OpenAccountService.run(
        member: Membership::Member.find(account_params[:member_id]),
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
        @members = Membership::Member.order(:last_name)
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

      @product = @account.share_product
      @cash_account = resolve_cash_account
      @notes = params[:notes]
      @price_per_share = @product.price_per_share

      amount_cents = parse_amount_cents(params[:amount])
      price_cents = @product.price_per_share_cents

      unless amount_cents&.positive?
        flash.now[:alert] = "Amount must be greater than zero."
        render :buy, status: :unprocessable_entity
        return
      end

      unless @cash_account
        flash.now[:alert] = "Select a cash on hand account."
        render :buy, status: :unprocessable_entity
        return
      end

      @shares = amount_cents / price_cents

      unless @shares.positive?
        flash.now[:alert] = "Amount must be at least #{@price_per_share.format} to purchase one share."
        render :buy, status: :unprocessable_entity
        return
      end

      if @account.shares_owned.zero? && @shares < @product.minimum_initial_purchase
        min_amount = Money.new(@product.minimum_initial_purchase * price_cents, "PHP")
        flash.now[:alert] = "Minimum initial purchase is #{@product.minimum_initial_purchase} shares (#{min_amount.format})."
        render :buy, status: :unprocessable_entity
        return
      end

      @amount_entered = Money.new(amount_cents, "PHP")
      @amount_input = params[:amount]
      @total_amount = Money.new(@shares * price_cents, "PHP")

      @debits = [ { account: @cash_account.name, amount: @total_amount.format } ]
      @credits = [ { account: @account.equity_account&.name || "Share Capital Equity", amount: @total_amount.format } ]

      render :buy
    end

    def confirm_buy
      @account = Equity::Account.find(params[:id])
      @cash_account = resolve_cash_account
      @notes = params[:notes]

      unless Current.cash_session
        redirect_to buy_equity_account_path(@account), alert: "No active cash session. Please log in again."
        return
      end

      amount_cents = parse_amount_cents(params[:amount])
      price_cents = @account.share_product.price_per_share_cents
      @shares = amount_cents.to_i / price_cents

      unless @shares.positive? && @cash_account
        redirect_to buy_equity_account_path(@account), alert: "Invalid purchase parameters."
        return
      end

      outcome = Equity::BuySharesService.run(
        share_capital_account: @account,
        shares: @shares,
        cash_account: @cash_account,
        cash_session: Current.cash_session,
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

    def parse_amount_cents(value)
      return nil if value.blank?
      (value.to_s.gsub(/[^0-9.]/, "").to_f * 100).round
    end
  end
end
