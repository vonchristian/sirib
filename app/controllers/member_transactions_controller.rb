class MemberTransactionsController < ApplicationController
  layout "shell"

  def new
    @member = Membership::Member.find(params[:member_id])
    load_accounts
    @cash_accounts = cash_accounts_for_select

    if @cash_accounts.empty?
      redirect_to @member, alert: "No cash accounts are linked to your profile. Contact an administrator."
    end
  end

  def preview
    @member = Membership::Member.find(params[:member_id])
    @cash_accounts = cash_accounts_for_select
    load_accounts
    @cash_account = resolve_cash_account
    @notes = params[:notes]
    @items = parse_items

    unless @items.any?
      flash.now[:alert] = "At least one valid transaction item is required."
      render :new, status: :unprocessable_entity
      return
    end

    unless @cash_account
      flash.now[:alert] = "Select a cash on hand account."
      render :new, status: :unprocessable_entity
      return
    end

    @total_amount = Money.new(@items.sum { |i| i[:amount_cents] }, "PHP")
    @debits = [{ account: @cash_account.name, amount: @total_amount.format }]
    @credits = @items.map { |i| { account: i[:credit_account_name], amount: Money.new(i[:amount_cents], "PHP").format } }

    render :new
  end

  def create
    @member = Membership::Member.find(params[:member_id])
    @cash_accounts = cash_accounts_for_select
    load_accounts
    @cash_account = resolve_cash_account
    @items = parse_items
    @notes = params[:notes]

    unless @items.any? && @cash_account
      redirect_to new_member_transaction_path(@member), alert: "Invalid transaction parameters."
      return
    end

    unless Current.cash_session
      redirect_to new_member_transaction_path(@member), alert: "No active cash session. Please log in again."
      return
    end

    outcome = MemberTransactionService.run(
      member: @member,
      cash_session: Current.cash_session,
      cash_account: @cash_account,
      items: @items,
      posted_by_id: Current.user.id,
      notes: @notes
    )

    if outcome.valid?
      redirect_to @member, notice: "Member transaction completed."
    else
      flash.now[:alert] = outcome.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  private

  def load_accounts
    @savings_accounts = Treasury::SavingsAccount.where(depositor_id: @member.id, depositor_type: "Member").active.includes(:savings_product).by_latest
    @share_accounts = Equity::Account.where(member: @member).active.includes(:share_product).by_latest
    @loans = Lending::Loan.where(member: @member).active.includes(:loan_product).order(created_at: :desc)
  end

  def parse_items
    items = []

    (params[:savings] || []).each do |_, data|
      next if data[:amount_cents].blank?
      amount_cents = parse_cents(data[:amount_cents])
      next unless amount_cents&.positive?
      account = Treasury::SavingsAccount.find_by(id: data[:account_id])
      next unless account&.liability_account
      items << {
        type: :savings_deposit,
        account: account,
        amount_cents: amount_cents,
        amount_input: data[:amount_cents],
        credit_account: account.liability_account,
        credit_account_name: account.liability_account.name
      }
    end

    (params[:loans] || []).each do |_, data|
      next if data[:amount_cents].blank?
      amount_cents = parse_cents(data[:amount_cents])
      next unless amount_cents&.positive?
      loan = Lending::Loan.find_by(id: data[:loan_id])
      next unless loan
      items << {
        type: :loan_payment,
        account: loan,
        amount_cents: amount_cents,
        amount_input: data[:amount_cents],
        credit_account: Accounting::Account.find_by(name: "Loans Receivable — Current"),
        credit_account_name: "Loans Receivable — Current"
      }
    end

    (params[:shares] || []).each do |_, data|
      next if data[:amount_cents].blank?
      amount_cents = parse_cents(data[:amount_cents])
      next unless amount_cents&.positive?
      account = Equity::Account.find_by(id: data[:account_id])
      next unless account&.equity_account
      items << {
        type: :share_purchase,
        account: account,
        amount_cents: amount_cents,
        amount_input: data[:amount_cents],
        credit_account: account.equity_account,
        credit_account_name: account.equity_account.name
      }
    end

    items
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

  def parse_cents(value)
    return nil if value.blank?
    (value.to_s.gsub(/[^0-9.]/, "").to_f * 100).round
  end
end
