module Ai
  module Tools
    class SavingsTool
      def self.call(branch:)
        new(branch).call
      end

      def initialize(branch)
        @branch = branch
      end

      def call
        member_ids = members.select(:id)
        accounts = Treasury::SavingsAccount.active.where(depositor: members)

        total_accounts = accounts.count
        total_balance_cents = accounts.sum { |a| a.liability_account&.balance&.cents.to_i }

        yesterday = Date.current - 1.day
        week_ago = Date.current - 7.days

        recent_entries = Accounting::Entry.joins(:amount_lines)
          .where(amount_lines: { account: accounts.filter_map(&:liability_account) })
          .where(posted_at: week_ago..)

        deposits = recent_entries.where(description: "Savings Deposit")
        withdrawals = recent_entries.where(description: "Savings Withdrawal")

        deposit_total_cents = deposits.sum { |e| e.amount_lines.credit.sum(:amount_cents) }
        withdrawal_total_cents = withdrawals.sum { |e| e.amount_lines.debit.sum(:amount_cents) }

        dormant_accounts = accounts.select { |a|
          last_txn = a.transactions.order(created_at: :desc).first
          last_txn.nil? || last_txn.created_at < 90.days.ago
        }

        low_balance_accounts = accounts.select { |a|
          (a.liability_account&.balance&.cents.to_i) < 100_00
        }

        {
          total_accounts: total_accounts,
          total_balance_cents: total_balance_cents,
          deposits_last_7d_count: deposits.count,
          deposits_last_7d_amount_cents: deposit_total_cents,
          withdrawals_last_7d_count: withdrawals.count,
          withdrawals_last_7d_amount_cents: withdrawal_total_cents,
          net_flow_last_7d_cents: deposit_total_cents - withdrawal_total_cents,
          dormant_accounts_count: dormant_accounts.count,
          low_balance_accounts_count: low_balance_accounts.count
        }
      end

      private

      def members
        Membership::Member.where(branch_id: @branch.id)
      end
    end
  end
end
