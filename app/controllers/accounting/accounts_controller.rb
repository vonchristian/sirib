module Accounting
  class AccountsController < ApplicationController
    layout "shell"

    def show
      @account = Accounting::Account.includes(:ledger).find(params[:id])
      @entries = Accounting::Entry.joins(:amount_lines)
        .where(amount_lines: { account_id: @account.id })
        .includes(amount_lines: :account)
        .order(posted_at: :desc, id: :desc)
        .limit(50)
    end

    def search
      query = params[:q]
      @accounts = if query.present?
        Accounting::Account.search(query).includes(:ledger).order(:account_code).limit(20)
      else
        Accounting::Account.none
      end

      render partial: "accounting/accounts/search_results", locals: { accounts: @accounts }
    end
  end
end
