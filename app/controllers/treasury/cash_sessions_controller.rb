module Treasury
  class CashSessionsController < ApplicationController
    layout "shell"
    helper_method :category_label

    def index
      @sessions = Treasury::CashSession.where(user: Current.user).by_latest
    end

    def show
      @session = Treasury::CashSession.find(params[:id])
      @vouchers = @session.vouchers.by_latest.includes(:cash_account, :counterparty, entry: { amount_lines: :account })
      @receipts = @vouchers.receipts.posted
      @disbursements = @vouchers.disbursements.posted
      @vault_transfers = @session.vault_transfers.order(created_at: :desc)
      @grouped_receipts = @receipts.group_by(&:category).sort_by { |cat, _| category_label(cat) }
      @grouped_disbursements = @disbursements.group_by(&:category).sort_by { |cat, _| category_label(cat) }
    end


  def receive_from_vault
    @session = Treasury::CashSession.find(params[:id])
    amount_cents = parse_amount_cents(params[:amount])

    result = Treasury::VaultTransferService.request_to_teller(
      cash_session: @session,
      amount_cents: amount_cents,
      description: params[:description]
    )

    if result.success?
      redirect_to treasury_cash_session_path(@session), notice: "Vault transfer request submitted for approval."
    else
      redirect_to treasury_cash_session_path(@session), alert: result.errors.join(", ")
    end
  end

  def return_to_vault
    @session = Treasury::CashSession.find(params[:id])
    amount_cents = parse_amount_cents(params[:amount])

    result = Treasury::VaultTransferService.request_to_vault(
      cash_session: @session,
      amount_cents: amount_cents,
      description: params[:description]
    )

    if result.success?
      redirect_to treasury_cash_session_path(@session), notice: "Vault return request submitted for approval."
    else
      redirect_to treasury_cash_session_path(@session), alert: result.errors.join(", ")
    end
  end

  def download_pdf
    @session = Treasury::CashSession.find(params[:id])
    @vouchers = @session.vouchers.by_latest.includes(:cash_account, :counterparty, entry: { amount_lines: :account })
    @receipts = @vouchers.receipts.posted
    @disbursements = @vouchers.disbursements.posted

    @grouped_receipts = @receipts.group_by(&:category).sort_by { |cat, _| category_label(cat) }
    @grouped_disbursements = @disbursements.group_by(&:category).sort_by { |cat, _| category_label(cat) }
    html = render_to_string("download_pdf", layout: "pdf")
    pdf = Grover.new(html, format: "Letter").to_pdf
    send_data pdf,
      filename: "closing_report_session_#{@session.id}.pdf",
      type: "application/pdf",
      disposition: "attachment"
  end

  private

  def parse_amount_cents(raw)
    (raw.to_f * 100).round
  end

  def category_label(cat)
    {
      "savings_deposit" => "Savings Deposits",
      "savings_withdrawal" => "Savings Withdrawals",
      "share_capital_purchase" => "Share Capital Purchases",
      "member_transaction" => "Member Transactions",
      "loan_payment" => "Loan Payments",
      "time_deposit" => "Time Deposits",
    }[cat] || cat.titleize
  end
end
end
