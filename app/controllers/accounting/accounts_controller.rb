module Accounting
  class AccountsController < ApplicationController
    layout "shell"

    def show
      @account = Accounting::Account.includes(:ledger).find(params[:id])
      @status_service = Accounting::AccountStatusService.new(account: @account)
      @query_service = Accounting::LedgerQueryService.new(
        account: @account,
        filters: build_filters,
        sort_order: params[:sort] || "desc"
      )

      scope = @query_service.scope
      @pagy, @amount_lines = pagy(scope, limit: 50)
      @ledger_lines = @query_service.build_ledger_lines(@amount_lines)
      @summary = @query_service.summary

      entry_scope = Accounting::Entry
        .where(id: @account.amount_lines.select(:entry_id).distinct)
        .includes(:created_by)
        .order(posted_at: :desc)

      audit_page = (params[:audit_page] || 1).to_i
      @pagy_audit, @audit_entries = pagy(entry_scope, limit: 50, page: audit_page)
    end

    def audit_entries
      account = Accounting::Account.includes(:ledger).find(params[:id])
      entry_scope = Accounting::Entry
        .where(id: account.amount_lines.select(:entry_id).distinct)
        .includes(:created_by)
        .order(posted_at: :desc)

      pagy, audit_entries = pagy(entry_scope, limit: 50, page: params[:audit_page] || 1)

      render partial: "accounting/accounts/audit_entries", locals: { audit_entries: audit_entries, pagy: pagy, account_id: account.id }, layout: false
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

    private

    def build_filters
      from_date = parse_date(:from_date)
      to_date = parse_date(:to_date)

      if params[:quick_range].present?
        range_dates = resolve_quick_range(params[:quick_range])
        from_date ||= range_dates[:from]
        to_date ||= range_dates[:to]
      end

      direction = params[:direction]
      debit_only = direction == "debit" ? "1" : params[:debit_only]
      credit_only = direction == "credit" ? "1" : params[:credit_only]

      {
        from_date: from_date,
        to_date: to_date,
        quick_range: params[:quick_range].presence,
        debit_only: debit_only,
        credit_only: credit_only,
        amount_min: params[:amount_min].presence,
        amount_max: params[:amount_max].presence,
        reference_number: params[:reference_number].presence,
        description: params[:description].presence,
        entry_type: params[:entry_type].presence,
        source_module: params[:source_module].presence
      }.compact
    end

    def parse_date(key)
      value = params[key]
      return nil if value.blank?
      Date.parse(value)
    rescue Date::Error
      nil
    end

    def resolve_quick_range(range)
      today = Date.current
      case range
      when "today"
        { from: today, to: today }
      when "this_week"
        { from: today.beginning_of_week, to: today.end_of_week }
      when "this_month"
        { from: today.beginning_of_month, to: today.end_of_month }
      when "last_month"
        { from: 1.month.ago.beginning_of_month.to_date, to: 1.month.ago.end_of_month.to_date }
      when "this_quarter"
        { from: today.beginning_of_quarter, to: today.end_of_quarter }
      when "year_to_date"
        { from: today.beginning_of_year, to: today }
      else
        {}
      end
    end
  end
end
