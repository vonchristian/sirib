module Accounting
  class BalanceSheetController < ApplicationController
    layout "shell"

    TYPE_LABELS = {
      "asset" => "ASSETS",
      "liability" => "LIABILITIES",
      "equity" => "EQUITY"
    }.freeze

    TYPE_ORDER = %w[asset liability equity].freeze

    def index
      @as_of_date = parse_date(params[:as_of_date]) || Date.current
      @comparison = params[:comparison].presence_in(%w[none prior_period prior_quarter prior_year]) || "none"
      @compare_date = compute_compare_date

      if use_materialized_view?
        @amounts = load_from_materialized_view
      else
        @amounts = Accounting::AccountBalance::RunningBalance.new(to_date: @as_of_date, cooperative: Current.cooperative).load_amounts
      end
      @compare_amounts = Accounting::AccountBalance::RunningBalance.new(to_date: @compare_date, cooperative: Current.cooperative).load_amounts if @compare_date

      @report = build_report
    end

    private

    def use_materialized_view?
      @as_of_date == Date.current && Reporting::BalanceSheet.by_cooperative(Current.cooperative).any?
    end

    def load_from_materialized_view
      amounts = {}
      Reporting::BalanceSheet.by_cooperative(Current.cooperative).with_balance.find_each do |row|
        amounts[row.account_id] = row.balance_cents
      end
      amounts
    end

    def parse_date(str)
      Date.parse(str)
    rescue ArgumentError, TypeError
      nil
    end

    def compute_compare_date
      case @comparison
      when "prior_period" then @as_of_date - 1.month
      when "prior_quarter" then @as_of_date - 3.months
      when "prior_year" then @as_of_date - 1.year
      end
    end

    def build_report
      TYPE_ORDER.filter_map do |type|
        groups = Accounting::Ledger.by_cooperative(Current.cooperative).where(account_type: type)
          .roots
          .includes(:accounts)
          .order(:account_code)
          .map { |ledger| build_ledger_group(ledger) }

        total = groups.sum(Money.new(0, "PHP")) { |g| g[:total] }
        total_cmp = @compare_date ? groups.sum(Money.new(0, "PHP")) { |g| g[:total_compare] } : nil

        { name: TYPE_LABELS[type], total: total, total_compare: total_cmp, ledger_groups: groups }
      end
    end

    def build_ledger_group(ledger)
      rows = build_account_rows(ledger.accounts)
      children = ledger.children.includes(:accounts).order(:account_code)
        .map { |child| build_ledger_group(child) }

      all_accounts = rows + children.flat_map { |g| g[:accounts] }
      total = all_accounts.sum(Money.new(0, "PHP")) { |r| r[:balance] }
      total_cmp = @compare_date ? all_accounts.sum(Money.new(0, "PHP")) { |r| r[:balance_compare] } : nil

      { ledger: ledger, total: total, total_compare: total_cmp, accounts: rows, children: children }
    end

    def build_account_rows(accounts)
      accounts.order(:account_code).map do |account|
        balance = if use_materialized_view?
                    Money.new(@amounts[account.id] || 0, "PHP")
        else
                    Accounting::AccountBalance.balance(account, @amounts)
        end
        balance_cmp = @compare_date ? Accounting::AccountBalance.balance(account, @compare_amounts) : nil

        { account: account, balance: balance, balance_compare: balance_cmp }
      end
    end
  end
end