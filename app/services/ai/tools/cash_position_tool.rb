module Ai
  module Tools
    class CashPositionTool
      def self.call(branch:)
        new(branch).call
      end

      def initialize(branch)
        @branch = branch
      end

      def call
        today = Date.current

        cash_accounts = Accounting::Account.joins(:ledger)
          .where(account_type: :asset, ledgers: { cooperative: Current.cooperative })
          .where("ledgers.account_code LIKE '111%'")

        total_vault_cents = cash_accounts.sum(&:balance).cents

        open_sessions = Treasury::CashSession.open
          .where(date: today)
          .where(user: users)

        unbalanced_sessions = open_sessions.select { |s|
          computed = s.computed_ending_balance
          actual = s.ending_balance_cents
          computed.present? && actual.present? && computed != actual
        }

        recent_closed = Treasury::CashSession.closed
          .where(date: today)
          .where(user: users)

        total_variance_cents = unbalanced_sessions.sum { |s|
          (s.computed_ending_balance.to_i - s.ending_balance_cents.to_i).abs
        }

        {
          vault_balance_cents: total_vault_cents,
          open_sessions_count: open_sessions.count,
          closed_sessions_count: recent_closed.count,
          unbalanced_sessions_count: unbalanced_sessions.count,
          total_variance_cents: total_variance_cents,
          cash_on_hand_cents: open_sessions.sum { |s| s.computed_ending_balance.to_i }
        }
      end

      private

      def users
        User.joins(:role_assignments)
          .where(management_role_assignments: { branch_id: @branch.id })
      end
    end
  end
end
