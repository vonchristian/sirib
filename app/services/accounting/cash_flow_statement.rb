module Accounting
  class CashFlowStatement < ActiveInteraction::Base
    SECTIONS = [
      {
        key: :operating,
        label: "CASH FLOWS FROM OPERATING ACTIVITIES",
        ledgers: -> {
          Ledger.current_asset
            .or(Ledger.current_liability)
            .or(Ledger.where(account_type: %w[revenue expense]))
        }
      },
      {
        key: :investing,
        label: "CASH FLOWS FROM INVESTING ACTIVITIES",
        ledgers: -> { Ledger.non_current_asset }
      },
      {
        key: :financing,
        label: "CASH FLOWS FROM FINANCING ACTIVITIES",
        ledgers: -> {
          Ledger.non_current_liability
            .or(Ledger.where(account_type: :equity))
        }
      }
    ].freeze

    date :from_date
    date :to_date
    object :user, class: User
    object :cooperative, class: Cooperative, default: nil

    def execute
      coop = cooperative

      @end_amounts = AccountBalance::RunningBalance.new(to_date: to_date, cooperative: coop).load_amounts
      @start_amounts = AccountBalance::RunningBalance.new(to_date: from_date - 1.day, cooperative: coop).load_amounts

      scope = coop ? Account.by_cooperative(coop) : Account
      @cash_accounts = scope.cash_accounts_for(user).non_contra.to_a
      @cash_ids = @cash_accounts.map(&:id)

      sections = build_sections
      totals = section_totals(sections)
      cash = cash_totals

      {
        sections: sections,
        net_change: totals[:net_change],
        cash_at_beginning: cash[:beginning],
        cash_at_end: cash[:end],
        cash_accounts: @cash_accounts
      }
    end

    private

    def build_sections
      SECTIONS.map do |section|
        ledger_scope = cooperative ? Ledger.by_cooperative(cooperative) : Ledger
        ledger_ids = ledger_scope.merge(section[:ledgers].call).pluck(:id)
        account_scope = cooperative ? Account.by_cooperative(cooperative) : Account
        accounts = account_scope.non_contra
          .where.not(id: @cash_ids)
          .where(ledger_id: ledger_ids)
          .includes(:ledger)
          .order(:account_code)

        rows = accounts.filter_map do |account|
          change = compute_change(account)
          amount = cash_flow_effect(change, account)
          { account: account, amount: amount } if amount.cents != 0
        end

        total = rows.sum(Money.new(0, "PHP")) { |r| r[:amount] }

        { name: section[:label], total: total, rows: rows }
      end
    end

    def compute_change(account)
      end_balance = AccountBalance.balance(account, @end_amounts)
      start_balance = AccountBalance.balance(account, @start_amounts)
      end_balance - start_balance
    end

    def cash_flow_effect(change, account)
      if account.normal_credit_balance?
        change
      else
        -change
      end
    end

    def section_totals(sections)
      operating = sections[0][:total]
      investing = sections[1][:total]
      financing = sections[2][:total]

      { operating: operating, investing: investing, financing: financing,
        net_change: operating + investing + financing }
    end

    def cash_totals
      beginning = @cash_accounts.sum(Money.new(0, "PHP")) do |a|
        AccountBalance.balance(a, @start_amounts)
      end
      ending = @cash_accounts.sum(Money.new(0, "PHP")) do |a|
        AccountBalance.balance(a, @end_amounts)
      end

      { beginning: beginning, end: ending }
    end
  end
end
