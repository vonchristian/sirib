module Treasury
  class LoansController < ApplicationController
    layout "dashboard"

    def index
      @loans = Lending::Loan.for_disbursement.includes(:member, :loan_product).order(created_at: :desc)
    end

    def disburse
      @loan = Lending::Loan.find(params[:id])

      if @loan.disbursed?
        return redirect_to treasury_loans_path, alert: "Loan already disbursed."
      end

      ActiveRecord::Base.transaction do
        @loan.update!(
          disbursed_at: Time.current,
          outstanding_principal_cents: @loan.principal_cents
        )

        entry = Accounting::Entry.create!(
          reference_number: "DIB-#{@loan.reference_number}",
          description: "Loan disbursement - #{@loan.member.name}",
          posted_at: Time.current
        )

        cash_account = Accounting::CashAccount.find_by(user: Current.user)&.account
        loan_receivable = Accounting::Account.find_or_create_by!(
          name: "Loans Receivable",
          account_type: "asset"
        )

        Accounting::AmountLine.create!(
          entry: entry,
          account: cash_account || loan_receivable,
          amount_type: "credit",
          amount_cents: @loan.principal_cents,
          amount_currency: "PHP"
        )
        Accounting::AmountLine.create!(
          entry: entry,
          account: loan_receivable,
          amount_type: "debit",
          amount_cents: @loan.principal_cents,
          amount_currency: "PHP"
        )

        @loan.loan_payments.create!(
          reference_number: "DIB-#{@loan.reference_number}",
          amount_cents: @loan.principal_cents,
          principal_cents: @loan.principal_cents,
          interest_cents: 0,
          penalty_cents: 0,
          payment_date: Date.current,
          entry: entry
        )
      end

      redirect_to treasury_loans_path, notice: "Loan disbursed. Voucher generated."
    rescue => e
      redirect_to treasury_loans_path, alert: "Disbursement failed: #{e.message}"
    end

    def voucher
      @loan = Lending::Loan.find(params[:id])
    end
  end
end
