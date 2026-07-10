module Accounting
  class TrialBalanceService < ActiveInteraction::Base
    date :as_of, default: Date.current
    object :cooperative, class: Cooperative, default: nil

    NORMAL_DEBIT_TYPES = %w[asset expense].freeze

    def execute
      if use_materialized_view?
        rows = query_materialized_view
      else
        rows = aggregate_amounts
      end

      accounts = if cooperative
                   Account.by_cooperative(cooperative).where(id: rows.map { |r| r["account_id"] }).includes(:ledger).index_by(&:id)
      else
                   Account.where(id: rows.map { |r| r["account_id"] }).includes(:ledger).index_by(&:id)
      end

      account_lines = rows.filter_map do |row|
        account = accounts[row["account_id"].to_i]
        next unless account

        debit_cents = row["debit_cents"].to_i
        credit_cents = row["credit_cents"].to_i
        net = if NORMAL_DEBIT_TYPES.include?(account.account_type)
          { debit_cents: debit_cents - credit_cents, credit_cents: 0 }
        else
          { debit_cents: 0, credit_cents: credit_cents - debit_cents }
        end

        {
          account: account,
          debit_cents: debit_cents,
          credit_cents: credit_cents,
          net_debit_cents: net[:debit_cents],
          net_credit_cents: net[:credit_cents]
        }
      end

      total_debit_cents = account_lines.sum { |l| l[:debit_cents] }
      total_credit_cents = account_lines.sum { |l| l[:credit_cents] }

      {
        as_of_date: as_of,
        accounts: account_lines,
        total_debit_cents: total_debit_cents,
        total_credit_cents: total_credit_cents,
        balanced: total_debit_cents == total_credit_cents
      }
    end

    private

    def use_materialized_view?
      as_of == Date.current && Reporting::TrialBalance.any?
    end

    def query_materialized_view
      scope = Reporting::TrialBalance.all
      scope = scope.by_cooperative(cooperative) if cooperative

      scope.select(
        "account_id",
        "(debit_cents - credit_cents) AS net_cents",
        "debit_cents",
        "credit_cents"
      ).map do |row|
        { "account_id" => row.account_id.to_s, "debit_cents" => row.debit_cents, "credit_cents" => row.credit_cents }
      end
    end

    def aggregate_amounts
      base = AmountLine
      base = base.by_cooperative(cooperative) if cooperative

      base.connection.select_all(
        base
          .joins(:entry)
          .merge(Entry.up_to(as_of))
          .select(
            "amount_lines.account_id",
            "SUM(CASE WHEN amount_lines.amount_type = 0 THEN amount_lines.amount_cents ELSE 0 END) AS debit_cents",
            "SUM(CASE WHEN amount_lines.amount_type = 1 THEN amount_lines.amount_cents ELSE 0 END) AS credit_cents"
          )
          .group("amount_lines.account_id")
          .to_sql
      )
    end
  end
end