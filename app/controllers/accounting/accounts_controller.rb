module Accounting
  class AccountsController < ApplicationController
    layout false

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
