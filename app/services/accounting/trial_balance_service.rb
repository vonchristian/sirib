module Accounting
  class TrialBalanceService < ActiveInteraction::Base
    date :as_of, default: Date.current

    NORMAL_DEBIT_TYPES = %w[asset expense].freeze

    def execute
      rows = aggregate_amounts

      accounts = Account.where(id: rows.map { |r| r["account_id"] }).includes(:ledger).index_by(&:id)

      account_lines = rows.map do |row|
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
      end.compact

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

    def aggregate_amounts
      AmountLine.connection.select_all(
        AmountLine
          .joins(:entry)
          .merge(Entry.up_to(as_of))
          .select(
            "amount_lines.account_id",
            "SUM(CASE WHEN amount_lines.amount_type = 0 THEN amount_lines.amount_cents ELSE 0 END) AS debit_cents",
            "SUM(CASE WHEN amount_lines.amount_type = 1 THEN amount_lines.amount_cents ELSE 0 END) AS credit_cents"
          )
          .group("amount_lines.account_id")
          .to_sql
      ).to_a
    end
  end
end
