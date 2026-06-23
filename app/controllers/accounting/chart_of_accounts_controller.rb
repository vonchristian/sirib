module Accounting
  class ChartOfAccountsController < ApplicationController
    layout "shell"

    before_action :set_service

    def index
      @accounts = @service.accounts_list(page: params[:page])
      @filters = filter_params
    end

    def search
      query = params[:q]
      results = @service.search(query)

      respond_to do |format|
        format.html { render partial: "accounting/chart_of_accounts/search_results", locals: results }
        format.json { render json: results }
      end
    end

    def accounts
      accounts = @service.accounts_list(
        ledger_id: params[:ledger_id],
        account_type: params[:account_type].presence,
        search: params[:search].presence,
        contra: params[:contra].presence,
        status: params[:status].presence,
        non_postable: params[:non_postable].presence,
        page: params[:page] || 1
      )

      respond_to do |format|
        format.html { render partial: "accounting/chart_of_accounts/account_table", locals: { accounts: accounts }, layout: false }
        format.turbo_stream
      end
    end

    private

    def set_service
      @service = Accounting::ChartOfAccountsService.new(cooperative: Current.cooperative)
    end

    def filter_params
      params.permit(:ledger_id, :account_type, :search, :contra, :status, :non_postable, :page)
    end
  end
end
